$tagsDir = "tag"
$postsDir = "_posts"
$global:newTags = $false
$global:addedNewTags = @()

function Set-OutputVariable($Name, $Value) {
    Write-Host "::set-output name=$Name::$Value"
}

function GetNewTags($path, $tagList) {
    $file = Get-Content -raw $path

    $pattern = "---(?s)(.*?)---"
    $tagReg = "tags: (.*)"

    $marker = [regex]::Match($file,$pattern).Groups[1].Value
    $lines = $marker.Split(
        @("`r`n", "`r", "`n"),
        [StringSplitOptions]::None
    )

    $result = @()
    if ($lines.Length -gt 0) {
        foreach($line in $lines) {
            $tags = [regex]::Match($line, $tagReg).Groups[1]
            if($tags.Length -gt 0) {
                $tags = $tags -split ' ' | ForEach-Object { $_.Trim() }

                foreach ($tag in $tags) {
                    if (-Not $tagList.Contains($tag)) {
                        $global:newTags = $true
                        $result += $tag
                        $global:addedNewTags += $tag
                    }
                }
            }
        }
    }
    
    if ($result.Length -gt 0) {
        Write-Host "Found new tags -> $generatedTags"
    }

    return $result
}

function CreateTags($post, $tagList) {
    $generatedTags = GetNewTags -path $post -tagList $tagList

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
            Write-Host "Creating tag file -> $tagsDir\$tag.md"
            $content | Out-File -FilePath "$tagsDir\$tag.md"
        }
    }
}


$posts = Get-ChildItem "$postsDir"
$tags = Get-ChildItem $tagsDir | foreach-object {(Split-Path -leaf $_) -replace ".md",""}

foreach ($post in $posts) {
    CreateTags -post $post.FullName -tagList $tags
}

# notify runner of status
Set-OutputVariable -Name "new-tags" -Value "$global:newTags"
Set-OutputVariable -Name "new-tags-added" -Value "$global:addedNewTags"
