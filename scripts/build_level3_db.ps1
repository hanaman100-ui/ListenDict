param(
    [int]$Count = 50,
    [string]$Output = "data/level3_lessons.json"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$headers = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
$rssUrl = 'https://breakingnewsenglish.com/rss.xml'
$archiveRanges = @(
    '2511-2602', '2507-2510', '2503-2506',
    '2411-2502', '2407-2410', '2403-2406',
    '2311-2402', '2307-2310', '2303-2306',
    '2211-2302', '2207-2210'
)

function Get-InnerText([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return '' }
    $decoded = [System.Net.WebUtility]::HtmlDecode($text)
    $clean = [regex]::Replace($decoded, '<[^>]+>', ' ')
    $clean = [regex]::Replace($clean, '\s+', ' ').Trim()
    return $clean
}

function New-DictationText([string]$title) {
    $t = [System.Net.WebUtility]::HtmlDecode($title)
    $t = $t.Trim().TrimEnd('.')
    return "Today's level three news focus is: $t."
}

function Get-DictationParagraphFromHtml([string]$html) {
    $articleMatch = [regex]::Match($html, '(?is)<article>(.*?)</article>')
    if (-not $articleMatch.Success) { return '' }

    $articleContent = $articleMatch.Groups[1].Value
    $pMatches = [regex]::Matches($articleContent, '(?is)<p>(.*?)</p>')

    foreach ($p in $pMatches) {
        $pHtml = $p.Groups[1].Value
        $pHtml = [regex]::Replace($pHtml, '(?is)<br\s*/?>', ' ')
        $text = Get-InnerText $pHtml
        if (-not [string]::IsNullOrWhiteSpace($text)) { return $text.Trim() }
    }

    return ''
}

function Get-Level3PageInfo([string]$url, [hashtable]$headers) {
    $html = (Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 25).Content

    if ($html -notmatch '(?is)The\s+Reading\s*/\s*Listening\s*-.*?Level\s*3') { return $null }

    $titleMatch = [regex]::Match($html, '(?is)<title>(.*?)</title>')
    $title = if ($titleMatch.Success) {
        (Get-InnerText $titleMatch.Groups[1].Value) -replace '\s*-\s*ESL Lesson Plan.*$', ''
    } else {
        'Level 3 lesson'
    }

    $dictation = Get-DictationParagraphFromHtml $html
    if ([string]::IsNullOrWhiteSpace($dictation)) {
        $dictation = New-DictationText $title
    }

    return [PSCustomObject]@{
        title = $title.Trim()
        url = $url
        level = 3
        dictation_text = $dictation
    }
}

$rows = @()
$seen = New-Object 'System.Collections.Generic.HashSet[string]'

# 1) RSS 최근 기사 우선 수집
$content = (Invoke-WebRequest -Uri $rssUrl -Headers $headers -UseBasicParsing -TimeoutSec 30).Content
$itemMatches = [regex]::Matches($content, '(?is)<item>(.*?)</item>')

foreach ($m in $itemMatches) {
    if ($rows.Count -ge $Count) { break }

    $item = $m.Groups[1].Value
    $titleMatch = [regex]::Match($item, '(?is)<title>(.*?)</title>')
    $linkMatch = [regex]::Match($item, '(?is)<link>(.*?)</link>')
    $dateMatch = [regex]::Match($item, '(?is)<pubDate>(.*?)</pubDate>')
    $descMatch = [regex]::Match($item, '(?is)<description>(.*?)</description>')

    if (-not $titleMatch.Success -or -not $linkMatch.Success) { continue }

    $title = Get-InnerText $titleMatch.Groups[1].Value
    $link = Get-InnerText $linkMatch.Groups[1].Value
    if ($link -notmatch '^https://breakingnewsenglish.com/') { continue }
    if (-not $seen.Add($link)) { continue }

    try {
        $info = Get-Level3PageInfo -url $link -headers $headers
        if (-not $info) { continue }
    } catch {
        continue
    }

    $rows += [PSCustomObject]@{
        id = $rows.Count + 1
        title = $title
        url = $link
        pub_date = (Get-InnerText $dateMatch.Groups[1].Value)
        source = 'Breaking News English'
        summary = (Get-InnerText $descMatch.Groups[1].Value)
        level = 3
        dictation_text = $info.dictation_text
    }
}

# 2) 아카이브 페이지에서 부족분 보강
if ($rows.Count -lt $Count) {
    foreach ($range in $archiveRanges) {
        if ($rows.Count -ge $Count) { break }
        $archiveUrl = "https://breakingnewsenglish.com/$range.html"

        try {
            $archiveHtml = (Invoke-WebRequest -Uri $archiveUrl -Headers $headers -UseBasicParsing -TimeoutSec 30).Content
        } catch {
            continue
        }

        $linkMatches = [regex]::Matches($archiveHtml, 'href="([0-9]{4}/[0-9]{6}-[a-z0-9-]+\.html)"')
        foreach ($lm in $linkMatches) {
            if ($rows.Count -ge $Count) { break }

            $rel = $lm.Groups[1].Value
            $link = "https://breakingnewsenglish.com/$rel"
            if (-not $seen.Add($link)) { continue }

            try {
                $info = Get-Level3PageInfo -url $link -headers $headers
                if (-not $info) { continue }

                $rows += [PSCustomObject]@{
                    id = $rows.Count + 1
                    title = $info.title
                    url = $link
                    pub_date = ''
                    source = 'Breaking News English'
                    summary = ''
                    level = 3
                    dictation_text = $info.dictation_text
                }
            } catch {
                continue
            }
        }
    }
}

if ($rows.Count -eq 0) {
    throw 'No lessons were collected from RSS.'
}

$outPath = if ([System.IO.Path]::IsPathRooted($Output)) { $Output } else { Join-Path (Get-Location) $Output }
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$payload = [PSCustomObject]@{
    generated_at = (Get-Date).ToString('o')
    source = $rssUrl
    note = 'Lesson metadata from Breaking News English. Dictation text is extracted from Level 3 article content when available.'
    count = $rows.Count
    lessons = $rows
}

$payload | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8
Write-Host "Saved $($rows.Count) lessons to $outPath"
