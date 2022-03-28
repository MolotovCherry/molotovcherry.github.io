$tagsDir = "tag"
$postsDir = "_posts"
$global:newTags = $false
$global:addedNewTags = @()

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

    return $result
}

function CreateTags($post, $tagList) {
    $generatedTags = GetNewTags -path $post -tagList $tagList

    if ($generatedTags.Length -gt 0) {
        Write-Output "Found new tags -> $generatedTags"

        foreach($tag in $generatedTags) {
            $content = @"
---
layout: tag_page
title: "Tag: $tag"
tag: $tag
robots: noindex
---
"@
            Write-Output "Creating tag file -> $tagsDir\$tag.md"
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
Write-Output "::set-output name=new-tags::${global:newTags}"
Write-Output "::set-output name=new-tags-added::${global:addedNewTags}"
