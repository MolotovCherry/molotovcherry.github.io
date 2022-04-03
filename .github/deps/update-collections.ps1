$tagsDir = "collections/_tags"
$categoryDir = "collections/_categories"
$authorDir = "collections/_authors"
$postsDir = "collections/_posts"
$global:changed = $false
$global:addedTags = @()
$global:deletedTags = @()
$global:addedCategories = @()
$global:deletedCategories = @()
$global:addedAuthor = @()
$global:deletedAuthor = @()

function Set-OutputVariable($Name, $Value) {
    Write-Host "::set-output name=$Name::$Value"
}

function Update($Posts, $TagList, $CategoryList, $AuthorList) {
    $tags = @()
    $categories = @()
    $author = @()
    foreach($post in $Posts) {
        $file = Get-Content -raw $post

        $pattern = "---(?s)(.*?)---"
        $tagReg = "tags: (.*)"
        $categoryReg = "category: (.*)"
        $authorReg = "author: (.*)"

        $marker = [regex]::Match($file,$pattern).Groups[1].Value
        $lines = $marker.Split(
            @("`r`n", "`r", "`n"),
            [StringSplitOptions]::None
        )

        if ($lines.Length -gt 0) {
            foreach($line in $lines) {
                $tagsFiltered = [regex]::Match($line, $tagReg).Groups[1]
                $categoriesFiltered = [regex]::Match($line, $categoryReg).Groups[1]
                $authorFiltered = [regex]::Match($line, $authorReg).Groups[1]
                if($tagsFiltered.Length -gt 0) {
                    $tags += $tagsFiltered -split ' ' | ForEach-Object { $_.Trim() }
                }
                if($categoriesFiltered.Length -gt 0) {
                    $categories += $categoriesFiltered -split ' ' | ForEach-Object { $_.Trim() }
                }
                if($authorFiltered.Length -gt 0) {
                    $author += $authorFiltered -split ' ' | ForEach-Object { $_.Trim() }
                }
            }
        }
    }

    # remove all duplicates
    $tags = $tags | Get-Unique
    $categories = $categories | Get-Unique
    $author = $author | Get-Unique

    $newTags = $tags | Where-Object {$TagList -NotContains $_}
    $deletedTags = $TagList | Where-Object {$tags -NotContains $_}
    $newCategories = $categories | Where-Object {$CategoryList -NotContains $_}
    $deletedCategories = $CategoryList | Where-Object {$categories -NotContains $_}
    $newAuthor = $author | Where-Object {$AuthorList -NotContains $_}
    $deletedAuthor = $AuthorList | Where-Object {$author -NotContains $_}

    if ($newTags.Length -gt 0) {
        Write-Host "Added tags -> $newTags"
        $global:changed = $true
        $global:addedTags += $newTags
        CreateTags $newTags
    }
    if ($deletedTags.Length -gt 0) {
        Write-Host "Deleted tags -> $deletedTags"
        $global:changed = $true
        $global:deletedTags += $deletedTags
        $deletedTags | ForEach-Object { Remove-Item -Path "$tagsDir\$_.md" }
    }
    if ($newCategories.Length -gt 0) {
        Write-Host "Added categories -> $newCategories"
        $global:changed = $true
        $global:addedCategories += $newCategories
        CreateCategories $newCategories
    }
    if ($deletedCategories.Length -gt 0) {
        Write-Host "Deleted categories -> $deletedCategories"
        $global:changed = $true
        $global:deletedCategories += $deletedCategories
        $deletedCategories | ForEach-Object { Remove-Item -Path "$categoryDir\$_.md" }
    }
    if ($newAuthor.Length -gt 0) {
        Write-Host "Added author -> $newAuthor"
        $global:changed = $true
        $global:addedAuthor += $newAuthor
        CreateAuthor $newAuthor
    }
    if ($deletedAuthor.Length -gt 0) {
        Write-Host "Deleted author -> $deletedAuthor"
        $global:changed = $true
        $global:deletedAuthor += $deletedAuthor
        $deletedAuthor | ForEach-Object { Remove-Item -Path "$authorDir\$_.md" }
    }
}

function CreateTags($generatedTags) {
    if (!(Test-Path $tagsDir)) {
        New-Item $tagsDir -ItemType Directory | Out-Null
    }

    foreach($tag in $generatedTags) {
        $content = @"
---
layout: tag-page
title: "Tag: $tag"
tag: $tag
robots: noindex
---
"@

        $tag = $tag.ToLower()
        $content | Out-File -FilePath "$tagsDir\$tag.md"
    }
}

function CreateCategories($generatedCategories) {
    if (!(Test-Path $categoryDir)) {
        New-Item $categoryDir -ItemType Directory | Out-Null
    }

    foreach($category in $generatedCategories) {
        $content = @"
---
layout: category-page
title: "Category: $category"
category: $category
robots: noindex
---
"@

        $category = $category.ToLower()
        $content | Out-File -FilePath "$categoryDir\$category.md"
    }
}

function CreateAuthor($generatedAuthor) {
    if (!(Test-Path $authorDir)) {
        New-Item $authorDir -ItemType Directory | Out-Null
    }

    foreach($author in $generatedAuthor) {
        $content = @"
---
name: $author
author: $author

layout: author-page
title: "Author: $author"
robots: noindex
---

{% comment %} Bio here {% endcomment %}
"@

        $author = $author.ToLower()
        $content | Out-File -FilePath "$authorDir\$author.md"
    }
}


$posts = Get-ChildItem "$postsDir" | ForEach-Object {$_.FullName}
$tags = @()
$categories = @()
$author = @()
if (Test-Path $tagsDir) {
    $tags += Get-ChildItem $tagsDir | foreach-object {(Split-Path -leaf $_) -replace ".md",""}
}
if (Test-Path $categoryDir) {
    $categories += Get-ChildItem $categoryDir | foreach-object {(Split-Path -leaf $_) -replace ".md",""}
}
if (Test-Path $authorDir) {
    $author += Get-ChildItem $authorDir | foreach-object {(Split-Path -leaf $_) -replace ".md",""}
}

Update -Posts $posts -TagList $tags -CategoryList $categories -AuthorList $author

# notify runner of status
Set-OutputVariable -Name "changed" -Value "$global:changed"
if ($global:changed) {
    if ($global:addedTags.Length -gt 0) {
        Set-OutputVariable -Name "new-tags" -Value "$global:addedTags"
    }
    if ($global:deletedTags.Length -gt 0) {
        Set-OutputVariable -Name "deleted-tags" -Value "$global:deletedTags"
    }
    if ($global:addedCategories.Length -gt 0) {
        Set-OutputVariable -Name "new-categories" -Value "$global:addedCategories"
    }
    if ($global:deletedCategories.Length -gt 0) {
        Set-OutputVariable -Name "deleted-categories" -Value "$global:deletedCategories"
    }
    if ($global:addedAuthor.Length -gt 0) {
        Set-OutputVariable -Name "new-author" -Value "$global:addedAuthor"
    }
    if ($global:deletedAuthor.Length -gt 0) {
        Set-OutputVariable -Name "deleted-author" -Value "$global:deletedAuthor"
    }
}
