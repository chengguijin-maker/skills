param(
    [string]$HostName = "630",
    [string]$RemoteRepoPath = "~/skills-repo",
    [string]$Agents = "both"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$archivePath = Join-Path $env:TEMP "skills-repo-sync-630.tar"

git -C $repoRoot archive --format=tar HEAD -o $archivePath

ssh $HostName "rm -rf $RemoteRepoPath && mkdir -p $RemoteRepoPath"
scp $archivePath "${HostName}:~/skills-repo.tar"
ssh $HostName "tar -xf ~/skills-repo.tar -C $RemoteRepoPath && rm -f ~/skills-repo.tar"
ssh $HostName "mkdir -p ~/.codex/skills ~/.claude/skills"
ssh $HostName "rm -rf ~/.codex/skills/skills-manager ~/.claude/skills/skills-manager"
ssh $HostName "cp -R $RemoteRepoPath/skills/skills-manager ~/.codex/skills/skills-manager"
ssh $HostName "cp -R $RemoteRepoPath/skills/skills-manager ~/.claude/skills/skills-manager"
ssh $HostName "python3 ~/.codex/skills/skills-manager/scripts/skills_manager.py --repo-url $RemoteRepoPath --ref main install --skill '*' --agent $Agents"

Remove-Item $archivePath -Force
