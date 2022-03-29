$tagsDir = "tag"
$postsDir = "_posts"
$global:changedTags = $false
$global:addedTags = @()
$global:deletedTags = @()

function Set-OutputVariable($Name, $Value) {
    Write-Host "::set-output name=$Name::$Value"
}

function UpdateTags($Posts, $TagList) {
    $tags = @()
    foreach($post in $Posts) {
        $file = Get-Content -raw $post

        $pattern = "---(?s)(.*?)---"
        $tagReg = "tags: (.*)"

        $marker = [regex]::Match($file,$pattern).Groups[1].Value
        $lines = $marker.Split(
            @("`r`n", "`r", "`n"),
            [StringSplitOptions]::None
        )

        if ($lines.Length -gt 0) {
            foreach($line in $lines) {
                $tagsFiltered = [regex]::Match($line, $tagReg).Groups[1]
                if($tagsFiltered.Length -gt 0) {
                    $tags += $tagsFiltered -split ' ' | ForEach-Object { $_.Trim() }
                }
            }
        }
    }

    # remove all duplicates
    $tags = $tags | Get-Unique

    $newTags = $tags | Where-Object {$TagList -NotContains $_}
    $deletedTags = $TagList | Where-Object {$tags -NotContains $_}

    if ($newTags.Length -gt 0) {
        Write-Host "Added tags -> $newTags"
        $global:changedTags = $true
        $global:addedTags += $newTags
        CreateTags $newTags
    }
    if ($deletedTags.Length -gt 0) {
        Write-Host "Deleted tags -> $deletedTags"
        $global:changedTags = $true
        $global:deletedTags += $deletedTags
        $deletedTags | ForEach-Object { Remove-Item -Path "$tagsDir\$_.md" }
    }
}

function CreateTags($generatedTags) {
    if ($generatedTags.Length -gt 0) {
        foreach($tag in $generatedTags) {
            $content = @"
---
layout: tag_page
title: "Tag: $tag"
tag: $tag
robots: noindex
---
"@

            $content | Out-File -FilePath "$tagsDir\$tag.md"
        }
    }
}


$posts = Get-ChildItem "$postsDir" | ForEach-Object {$_.FullName}
$tags = Get-ChildItem $tagsDir | foreach-object {(Split-Path -leaf $_) -replace ".md",""}

UpdateTags -Posts $posts -TagList $tags

# notify runner of status
Set-OutputVariable -Name "changed-tags" -Value "$global:changedTags"
if ($global:changedTags) {
    if ($global:addedTags.Length -gt 0) {
        Set-OutputVariable -Name "new-tags" -Value "$global:addedTags"
    }
    if ($global:deletedTags.Length -gt 0) {
        Set-OutputVariable -Name "deleted-tags" -Value "$global:deletedTags"
    }
}
