param(
    [string]$SkillRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$GraphRelativePath = "references\system-map-2026-05-07\confluence-directory-graph-level2",
    [string]$TreeRelativePath = "references\system-map-2026-05-07\confluence-directory-tree-level2",
    [string]$SpaceMapRelativePath = "references\system-map-2026-05-07\confluence-spaces-map.csv"
)

$ErrorActionPreference = "Stop"

$GraphRoot = Join-Path $SkillRoot $GraphRelativePath
$TreeRoot = Join-Path $SkillRoot $TreeRelativePath
$SpaceMapPath = Join-Path $SkillRoot $SpaceMapRelativePath

$nodePath = Join-Path $GraphRoot "confluence-目录图谱节点.csv"
$edgePath = Join-Path $GraphRoot "confluence-目录图谱关系.csv"
$spaceTopicPath = Join-Path $GraphRoot "confluence-空间主题关系.csv"
$spaceOverviewPath = Join-Path $GraphRoot "confluence-空间图谱摘要.csv"
$treePath = Join-Path $TreeRoot "confluence-空间目录树总表.csv"
$fetchErrorPath = Join-Path $TreeRoot "confluence-空间目录树抓取错误.csv"
$reportPath = Join-Path $GraphRoot "confluence-目录图谱校验报告.md"

$nodes = Import-Csv -LiteralPath $nodePath -Encoding UTF8
$edges = Import-Csv -LiteralPath $edgePath -Encoding UTF8
$spaceTopicEdges = Import-Csv -LiteralPath $spaceTopicPath -Encoding UTF8
$spaceOverview = Import-Csv -LiteralPath $spaceOverviewPath -Encoding UTF8
$treeRows = Import-Csv -LiteralPath $treePath -Encoding UTF8
$spaces = Import-Csv -LiteralPath $SpaceMapPath -Encoding UTF8
$fetchErrors = Import-Csv -LiteralPath $fetchErrorPath -Encoding UTF8

$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Detail
    )

    $script:checks.Add([pscustomobject]@{
        "检查项" = $Name
        "结果" = if ($Passed) { "通过" } else { "失败" }
        "说明" = $Detail
    }) | Out-Null
}

$nodeIds = @{}
foreach ($node in $nodes) {
    if (-not $nodeIds.ContainsKey($node."节点ID")) {
        $nodeIds[$node."节点ID"] = 0
    }
    $nodeIds[$node."节点ID"]++
}

$duplicateNodeIds = @($nodeIds.GetEnumerator() | Where-Object { $_.Value -gt 1 })
Add-Check -Name "节点ID唯一" -Passed ($duplicateNodeIds.Count -eq 0) -Detail "重复节点ID数量: $($duplicateNodeIds.Count)"

$danglingEdges = @($edges | Where-Object { -not $nodeIds.ContainsKey($_."源节点ID") -or -not $nodeIds.ContainsKey($_."目标节点ID") })
Add-Check -Name "关系端点存在" -Passed ($danglingEdges.Count -eq 0) -Detail "悬空关系数量: $($danglingEdges.Count)"

$spaceNodes = @($nodes | Where-Object { $_."节点类型" -eq "空间" })
$pageNodes = @($nodes | Where-Object { $_."节点类型" -eq "目录页面" })
$topicNodes = @($nodes | Where-Object { $_."节点类型" -eq "主题" })

Add-Check -Name "空间节点覆盖" -Passed ($spaceNodes.Count -eq $spaces.Count) -Detail "空间节点: $($spaceNodes.Count), 空间清单: $($spaces.Count)"
Add-Check -Name "目录页面节点覆盖" -Passed ($pageNodes.Count -eq $treeRows.Count) -Detail "目录页面节点: $($pageNodes.Count), 目录树行数: $($treeRows.Count)"

$spaceNodeKeys = @($spaceNodes | ForEach-Object { $_."空间键" } | Sort-Object -Unique)
$spaceMapKeys = @($spaces | ForEach-Object { $_.Key } | Sort-Object -Unique)
$missingSpaceNodes = @($spaceMapKeys | Where-Object { $spaceNodeKeys -notcontains $_ })
$extraSpaceNodes = @($spaceNodeKeys | Where-Object { $spaceMapKeys -notcontains $_ })
Add-Check -Name "空间键集合一致" -Passed ($missingSpaceNodes.Count -eq 0 -and $extraSpaceNodes.Count -eq 0) -Detail "缺失空间: $($missingSpaceNodes -join '; '); 多余空间: $($extraSpaceNodes -join '; ')"

$treePageIds = @($treeRows | ForEach-Object { "page:$($_.'页面ID')" } | Sort-Object -Unique)
$graphPageIds = @($pageNodes | ForEach-Object { $_."节点ID" } | Sort-Object -Unique)
$missingPageNodes = @($treePageIds | Where-Object { $graphPageIds -notcontains $_ })
$extraPageNodes = @($graphPageIds | Where-Object { $treePageIds -notcontains $_ })
Add-Check -Name "页面节点和目录树一致" -Passed ($missingPageNodes.Count -eq 0 -and $extraPageNodes.Count -eq 0) -Detail "缺失页面节点: $($missingPageNodes.Count); 多余页面节点: $($extraPageNodes.Count)"

$homepageRows = @($treeRows | Where-Object { [string]::IsNullOrWhiteSpace($_."父页面ID") })
$homepageEdges = @($edges | Where-Object { $_."关系类型" -eq "空间首页" })
Add-Check -Name "空间首页关系数量" -Passed ($homepageEdges.Count -eq $homepageRows.Count -and $homepageRows.Count -eq $spaces.Count) -Detail "空间首页关系: $($homepageEdges.Count), 首页行: $($homepageRows.Count), 空间数: $($spaces.Count)"

$containRows = @($treeRows | Where-Object { -not [string]::IsNullOrWhiteSpace($_."父页面ID") })
$containEdges = @($edges | Where-Object { $_."关系类型" -eq "包含目录" })
Add-Check -Name "包含目录关系数量" -Passed ($containEdges.Count -eq $containRows.Count) -Detail "包含目录关系: $($containEdges.Count), 非首页目录行: $($containRows.Count)"

$topicRows = @($treeRows | ForEach-Object { $_."主题推断" } | Sort-Object -Unique)
$topicNodeNames = @($topicNodes | ForEach-Object { $_."名称" } | Sort-Object -Unique)
$missingTopicNodes = @($topicRows | Where-Object { $topicNodeNames -notcontains $_ })
Add-Check -Name "主题节点覆盖" -Passed ($missingTopicNodes.Count -eq 0) -Detail "主题节点: $($topicNodes.Count), 缺失主题: $($missingTopicNodes -join '; ')"

$topicInferenceEdges = @($edges | Where-Object { $_."关系类型" -eq "推断主题" })
Add-Check -Name "推断主题关系数量" -Passed ($topicInferenceEdges.Count -eq $treeRows.Count) -Detail "推断主题关系: $($topicInferenceEdges.Count), 目录树行数: $($treeRows.Count)"

$spaceTopicExpected = $treeRows | Group-Object '空间键','主题推断' | ForEach-Object {
    $groupRows = @($_.Group)
    "$($groupRows[0].'空间键')|$($groupRows[0].'主题推断')|$($groupRows.Count)"
}
$spaceTopicActual = $spaceTopicEdges | ForEach-Object {
    $topic = $_."目标节点ID" -replace '^topic:', ''
    "$($_.'空间键')|$topic|$($_.'权重')"
}
$missingSpaceTopic = @($spaceTopicExpected | Where-Object { $spaceTopicActual -notcontains $_ })
$extraSpaceTopic = @($spaceTopicActual | Where-Object { $spaceTopicExpected -notcontains $_ })
Add-Check -Name "空间主题权重可回算" -Passed ($missingSpaceTopic.Count -eq 0 -and $extraSpaceTopic.Count -eq 0) -Detail "缺失空间主题关系: $($missingSpaceTopic.Count); 多余或权重不一致: $($extraSpaceTopic.Count)"

$overviewKeys = @($spaceOverview | ForEach-Object { $_."空间键" } | Sort-Object -Unique)
$missingOverview = @($spaceMapKeys | Where-Object { $overviewKeys -notcontains $_ })
Add-Check -Name "空间图谱摘要覆盖" -Passed ($missingOverview.Count -eq 0 -and $spaceOverview.Count -eq $spaces.Count) -Detail "摘要空间数: $($spaceOverview.Count), 缺失: $($missingOverview -join '; ')"

Add-Check -Name "目录抓取错误为空" -Passed ($fetchErrors.Count -eq 0) -Detail "抓取错误行数: $($fetchErrors.Count)"

$sensitiveMatches = Select-String -Path (Join-Path $GraphRoot "*") -Pattern "password|os_password|CONFLUENCE_PASSWORD|credential" -CaseSensitive:$false
Add-Check -Name "敏感词检查" -Passed ($null -eq $sensitiveMatches -or @($sensitiveMatches).Count -eq 0) -Detail "敏感词命中数: $(@($sensitiveMatches).Count)"

$relationSummary = $edges | Group-Object "关系类型" | Sort-Object Name | ForEach-Object { "$($_.Name): $($_.Count)" }
$nodeSummary = $nodes | Group-Object "节点类型" | Sort-Object Name | ForEach-Object { "$($_.Name): $($_.Count)" }
$failedChecks = @($checks | Where-Object { $_."结果" -ne "通过" })
$status = if ($failedChecks.Count -eq 0) { "通过" } else { "存在问题" }

$report = @"
# Confluence 目录图谱校验报告

校验时间: 2026-05-08

## 结论

校验结论: $status

## 规模

- 空间清单数量: $($spaces.Count)
- 目录树行数: $($treeRows.Count)
- 图谱节点数: $($nodes.Count)
- 图谱关系数: $($edges.Count)

## 节点类型分布

$($nodeSummary | ForEach-Object { "- $_" } | Out-String)
## 关系类型分布

$($relationSummary | ForEach-Object { "- $_" } | Out-String)
## 检查项

$($checks | ForEach-Object { "- $($_.'检查项'): $($_.'结果')。$($_.'说明')" } | Out-String)
## 说明

本校验只验证目录图谱相对目录树源数据的结构完整性和一致性, 不验证页面正文内容, 也不验证 Confluence 当前实时状态是否已经变化。
"@

$report | Set-Content -LiteralPath $reportPath -Encoding UTF8

if ($failedChecks.Count -gt 0) {
    $failedChecks | Format-Table -AutoSize
    throw "Confluence directory graph validation failed: $($failedChecks.Count) failed checks."
}

[pscustomobject]@{
    "结论" = $status
    "失败检查数" = $failedChecks.Count
    "节点数" = $nodes.Count
    "关系数" = $edges.Count
    "目录树行数" = $treeRows.Count
    "报告路径" = $reportPath
} | ConvertTo-Json
