<#
.SYNOPSIS
    Login to Hisense Coremail through SSO and export Coremail session variables.
.DESCRIPTION
    Automates the SSO webLocalAuth login flow:
    1. Initialize an SSO web session.
    2. Query login policy and RSA public key.
    3. Encrypt the password with RSA PKCS#1 v1.5.
    4. Submit doLogin.
    5. Follow the redirect chain into Coremail.
    6. Extract sid and Cookie header for coremail_query.ps1.

    The password is never written to disk. Use -Persist only for sid and cookies.
.EXAMPLE
    .\coremail_login.ps1 -Username $env:COREMAIL_USERNAME
.EXAMPLE
    .\coremail_login.ps1 -Username $env:COREMAIL_USERNAME -RunFolders
#>

param(
    [string]$Username = $env:COREMAIL_USERNAME,
    [string]$PasswordPlainText = $env:COREMAIL_PASSWORD,
    [string]$CredentialPath = (Join-Path $env:USERPROFILE ".qoder\skills\accessing-coremail-api\coremail_credential.xml"),
    [switch]$SaveCredential,
    [switch]$Persist,
    [switch]$RunFolders,
    [string]$SsoBaseUrl = "https://sso.hisense.com",
    [string]$MailBaseUrl = "https://mail.hisense.com"
)

$ErrorActionPreference = "Stop"

function New-RandomBase64Text {
    param([int]$ByteCount = 48)

    $bytes = New-Object byte[] $ByteCount
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes)
}

function Read-DerLength {
    param(
        [byte[]]$Bytes,
        [ref]$Offset
    )

    $first = $Bytes[$Offset.Value]
    $Offset.Value++
    if (($first -band 0x80) -eq 0) {
        return $first
    }

    $count = $first -band 0x7F
    $length = 0
    for ($i = 0; $i -lt $count; $i++) {
        $length = ($length -shl 8) -bor $Bytes[$Offset.Value]
        $Offset.Value++
    }
    return $length
}

function Read-DerValue {
    param(
        [byte[]]$Bytes,
        [ref]$Offset,
        [byte]$ExpectedTag
    )

    $tag = $Bytes[$Offset.Value]
    $Offset.Value++
    if ($tag -ne $ExpectedTag) {
        throw ("Unexpected DER tag. expected=0x{0:X2} actual=0x{1:X2}" -f $ExpectedTag, $tag)
    }

    $length = Read-DerLength -Bytes $Bytes -Offset $Offset
    $value = New-Object byte[] $length
    [Array]::Copy($Bytes, $Offset.Value, $value, 0, $length)
    $Offset.Value += $length
    return $value
}

function ConvertFrom-SubjectPublicKeyInfo {
    param([string]$PublicKeyBase64)

    $spkiBytes = [Convert]::FromBase64String($PublicKeyBase64)
    $offset = 0
    $spki = Read-DerValue -Bytes $spkiBytes -Offset ([ref]$offset) -ExpectedTag 0x30

    $innerOffset = 0
    [void](Read-DerValue -Bytes $spki -Offset ([ref]$innerOffset) -ExpectedTag 0x30)
    $bitString = Read-DerValue -Bytes $spki -Offset ([ref]$innerOffset) -ExpectedTag 0x03
    if ($bitString[0] -ne 0) {
        throw "Unsupported DER bit string with unused bits."
    }

    $rsaBytes = New-Object byte[] ($bitString.Length - 1)
    [Array]::Copy($bitString, 1, $rsaBytes, 0, $rsaBytes.Length)

    $rsaOffset = 0
    $rsaSequence = Read-DerValue -Bytes $rsaBytes -Offset ([ref]$rsaOffset) -ExpectedTag 0x30
    $rsaSequenceOffset = 0
    $modulus = Read-DerValue -Bytes $rsaSequence -Offset ([ref]$rsaSequenceOffset) -ExpectedTag 0x02
    $exponent = Read-DerValue -Bytes $rsaSequence -Offset ([ref]$rsaSequenceOffset) -ExpectedTag 0x02

    if ($modulus.Length -gt 1 -and $modulus[0] -eq 0) {
        $trimmed = New-Object byte[] ($modulus.Length - 1)
        [Array]::Copy($modulus, 1, $trimmed, 0, $trimmed.Length)
        $modulus = $trimmed
    }

    return [System.Security.Cryptography.RSAParameters]@{
        Modulus = $modulus
        Exponent = $exponent
    }
}

function Protect-PasswordWithPublicKey {
    param(
        [string]$Password,
        [string]$PublicKeyBase64
    )

    $parameters = ConvertFrom-SubjectPublicKeyInfo -PublicKeyBase64 $PublicKeyBase64
    $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider
    try {
        $rsa.ImportParameters($parameters)
        $plainBytes = [Text.Encoding]::UTF8.GetBytes($Password)
        $encryptedBytes = $rsa.Encrypt($plainBytes, $false)
        return [Convert]::ToBase64String($encryptedBytes)
    } finally {
        $rsa.Dispose()
    }
}

function Add-SessionCookie {
    param(
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
        [string]$Url,
        [string]$Name,
        [string]$Value,
        [string]$Domain = ""
    )

    $uri = [uri]$Url
    $cookie = New-Object System.Net.Cookie
    $cookie.Name = $Name
    $cookie.Value = $Value
    $cookie.Path = "/"
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $cookie.Domain = $uri.Host
    } else {
        $cookie.Domain = $Domain
    }
    $Session.Cookies.Add($uri, $cookie)
}

function Get-CookieHeader {
    param(
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session,
        [string]$Url
    )

    $cookies = $Session.Cookies.GetCookies($Url)
    return (($cookies | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; ")
}

function Get-Headers {
    param(
        [string]$Referer,
        [string]$BrowserId,
        [string]$BrowserId2,
        [string]$Accept = "application/json, text/plain, */*",
        [string]$ContentType = ""
    )

    $headers = @{
        "Accept" = $Accept
        "Accept-Language" = "zh-CN"
        "language" = "zh-CN"
        "Referer" = $Referer
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
        "BrowserId" = $BrowserId
        "BrowserId2" = $BrowserId2
    }

    if (-not [string]::IsNullOrWhiteSpace($ContentType)) {
        $headers["Content-Type"] = $ContentType
    }
    return $headers
}

$savedCredential = $null
if ([string]::IsNullOrWhiteSpace($PasswordPlainText) -and (Test-Path -LiteralPath $CredentialPath)) {
    try {
        $savedCredential = Import-Clixml -LiteralPath $CredentialPath
        if ([string]::IsNullOrWhiteSpace($Username)) {
            $Username = $savedCredential.UserName
        }
    } catch {
        Write-Warning "Failed to load saved credential. A password prompt will be used."
        $savedCredential = $null
    }
}

if ([string]::IsNullOrWhiteSpace($Username)) {
    $Username = Read-Host "Coremail username"
}

if ([string]::IsNullOrWhiteSpace($PasswordPlainText)) {
    if ($savedCredential) {
        $securePassword = $savedCredential.Password
    } else {
        $securePassword = Read-Host "Coremail password" -AsSecureString
    }
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        $PasswordPlainText = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
}

if ($Username -notmatch "@") {
    $UsernameForLogin = "$Username@hisense.com"
} else {
    $UsernameForLogin = $Username
}

if ($SaveCredential) {
    $credentialDirectory = Split-Path -Parent $CredentialPath
    if (-not (Test-Path -LiteralPath $credentialDirectory)) {
        New-Item -ItemType Directory -Force -Path $credentialDirectory | Out-Null
    }
    $secureToSave = ConvertTo-SecureString $PasswordPlainText -AsPlainText -Force
    $credentialToSave = New-Object System.Management.Automation.PSCredential($Username, $secureToSave)
    $credentialToSave | Export-Clixml -LiteralPath $CredentialPath
}

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$browserId = New-RandomBase64Text
$browserId2 = New-RandomBase64Text
$loginPage = "$SsoBaseUrl/login/emailLogin.html"
$mailAuthorizeUrl = "$SsoBaseUrl/esc-sso/oauth2.0/authorize?client_id=sys_mail&response_type=code&redirect_uri=https%3A%2F%2Fmail.hisense.com%2Fcoremail%2Fcmcu_addon%2Fsso.jsp&target_uri=https%3A%2F%2Fmail.hisense.com%2Fcoremail%2Fcmcu_addon%2Fsso.jsp"

Add-SessionCookie -Session $session -Url $SsoBaseUrl -Name "SessionLoginRedirectUrl" -Value $mailAuthorizeUrl -Domain "sso.hisense.com"
Add-SessionCookie -Session $session -Url $SsoBaseUrl -Name "language" -Value "zh-CN" -Domain "sso.hisense.com"
Add-SessionCookie -Session $session -Url $SsoBaseUrl -Name "BrowserId" -Value ([uri]::EscapeDataString($browserId)) -Domain "sso.hisense.com"
Add-SessionCookie -Session $session -Url $SsoBaseUrl -Name "BrowserId2" -Value ([uri]::EscapeDataString($browserId2)) -Domain "sso.hisense.com"

$pageHeaders = Get-Headers -Referer $loginPage -BrowserId $browserId -BrowserId2 $browserId2 -Accept "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
[void](Invoke-WebRequest -Uri $loginPage -WebSession $session -Headers $pageHeaders -UseBasicParsing -TimeoutSec 30)

$jsonHeaders = Get-Headers -Referer $loginPage -BrowserId $browserId -BrowserId2 $browserId2
[void](Invoke-RestMethod -Uri "$SsoBaseUrl/ngw/context?_=$(Get-Date -UFormat %s)" -WebSession $session -Headers $jsonHeaders -TimeoutSec 30)
$policy = Invoke-RestMethod -Uri "$SsoBaseUrl/esc-sso/api/v3/auth/queryAllValid?_=$(Get-Date -UFormat %s)" -WebSession $session -Headers $jsonHeaders -TimeoutSec 30

if ($policy.code -ne "0") {
    throw "Failed to query SSO login policy. code=$($policy.code) msg=$($policy.msg)"
}

$publicKey = $policy.data.param.publicKey
$publicKeyId = $policy.data.param.publicKeyId
if ([string]::IsNullOrWhiteSpace($publicKey) -or [string]::IsNullOrWhiteSpace($publicKeyId)) {
    throw "SSO login policy did not return an RSA public key."
}

$userValidUrl = "$SsoBaseUrl/esc-sso/api/v3/auth/queryUserValid?username=$([uri]::EscapeDataString($UsernameForLogin))&authType=webLocalAuth&_=$(Get-Date -UFormat %s)"
$userValid = Invoke-RestMethod -Uri $userValidUrl -WebSession $session -Headers $jsonHeaders -TimeoutSec 30
if ($userValid.code -ne "0") {
    throw "Failed to query user login validity. code=$($userValid.code) msg=$($userValid.msg)"
}
if ($userValid.data -and $userValid.data.type) {
    throw "SSO requires extra verification: $($userValid.data.type). Browser automation or manual login is required."
}
if ($userValid.data -and $userValid.data.enable -eq $false) {
    throw "SSO reports that this user cannot use webLocalAuth."
}

$encryptedPassword = Protect-PasswordWithPublicKey -Password $PasswordPlainText -PublicKeyBase64 $publicKey
$loginBody = @{
    authType = "webLocalAuth"
    dataField = @{
        username = $UsernameForLogin
        password = $encryptedPassword
        vcode = ""
        publicKeyId = $publicKeyId
    }
    redirectUri = ""
} | ConvertTo-Json -Depth 8 -Compress

$loginHeaders = Get-Headers -Referer $loginPage -BrowserId $browserId -BrowserId2 $browserId2 -ContentType "application/json; charset=UTF-8"
$loginResult = Invoke-RestMethod -Uri "$SsoBaseUrl/esc-sso/api/v3/auth/doLogin?_=$(Get-Date -UFormat %s)" -WebSession $session -Headers $loginHeaders -Body $loginBody -Method Post -TimeoutSec 30

if ($loginResult.code -ne "0") {
    $message = if ($loginResult.msg) { $loginResult.msg } else { $loginResult | ConvertTo-Json -Depth 8 -Compress }
    throw "SSO login failed. code=$($loginResult.code) msg=$message"
}

$redirect = $loginResult.data.redirect
if ([string]::IsNullOrWhiteSpace($redirect)) {
    throw "SSO login succeeded but no redirect URL was returned."
}
if ($redirect -notmatch "^https?://") {
    if ($redirect.StartsWith("/")) {
        $redirect = "$SsoBaseUrl$redirect"
    } else {
        $redirect = "$SsoBaseUrl/$redirect"
    }
}

$mailHeaders = Get-Headers -Referer $loginPage -BrowserId $browserId -BrowserId2 $browserId2 -Accept "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
$mailResponse = Invoke-WebRequest -Uri $redirect -WebSession $session -Headers $mailHeaders -UseBasicParsing -MaximumRedirection 10 -TimeoutSec 60
$finalUrl = $mailResponse.BaseResponse.ResponseUri.AbsoluteUri

$sid = $null
if ($finalUrl -match "[?&]sid=([^&#]+)") {
    $sid = [uri]::UnescapeDataString($Matches[1])
}

if ([string]::IsNullOrWhiteSpace($sid)) {
    $mailMain = Invoke-WebRequest -Uri "$MailBaseUrl/coremail/main.jsp" -WebSession $session -Headers $mailHeaders -UseBasicParsing -MaximumRedirection 10 -TimeoutSec 60
    $mainUrl = $mailMain.BaseResponse.ResponseUri.AbsoluteUri
    if ($mainUrl -match "[?&]sid=([^&#]+)") {
        $sid = [uri]::UnescapeDataString($Matches[1])
        $finalUrl = $mainUrl
    }
}

if ([string]::IsNullOrWhiteSpace($sid)) {
    throw "Coremail login completed but sid could not be extracted. Final URL: $finalUrl"
}

$cookieHeader = Get-CookieHeader -Session $session -Url $MailBaseUrl
if ($cookieHeader -notmatch [regex]::Escape($sid)) {
    Write-Warning "Extracted Cookie header does not contain the sid. Query requests may fail."
}

$env:COREMAIL_SID = $sid
$env:COREMAIL_COOKIE = $cookieHeader

if ($Persist) {
    [Environment]::SetEnvironmentVariable("COREMAIL_SID", $sid, "User")
    [Environment]::SetEnvironmentVariable("COREMAIL_COOKIE", $cookieHeader, "User")
    [Environment]::SetEnvironmentVariable("COREMAIL_USERNAME", $Username, "User")
}

[pscustomobject]@{
    sid = $sid
    cookieNames = (($session.Cookies.GetCookies($MailBaseUrl) | ForEach-Object { $_.Name }) -join ",")
    finalUrl = $finalUrl
    persisted = [bool]$Persist
    credentialSaved = [bool]$SaveCredential
}

if ($RunFolders) {
    $queryScript = Join-Path $PSScriptRoot "coremail_query.ps1"
    & $queryScript -Action Folders | Select-Object -First 10
}
