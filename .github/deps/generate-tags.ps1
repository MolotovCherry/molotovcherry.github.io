$tagsDir = "tag"
$postsDir = "_posts"
$addedNewTags = false
$newTags = @()

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
                $tags = $tags -split ' '
                $tags = $tags | Where-Object {$tagList -NotContains $_}

                $tags | foreach-object {
                    $result += $_
                    $newTags += $_
                }
            }
        }
    }

    return $result
}

function CreateTags($post, $tagList) {
    $newTags = GetNewTags -path $post -tagList $tagList

    if ($newTags.Length -gt 0) {
        $addedNewTags = true
        Write-Output "Found new tags -> $newTags"
    }

    foreach($tag in $newTags) {
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


$posts = Get-ChildItem "$postsDir"
$tags = Get-ChildItem $tagsDir | foreach-object {$_ -replace ".md",""}

foreach ($post in $posts) {
    CreateTags -post $post.FullName -tagList $tags
}

# notify runner of status
Write-Output "::set-output name=NewTagsAdded::$addedNewTags"
Write-Output "::set-output name=NewTags::$newTags"
