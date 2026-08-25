$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$dashboardPath = Join-Path `
    $projectRoot `
    "lib\features\dashboard\dashboard_screen.dart"

if (-not (Test-Path $dashboardPath)) {
    throw "dashboard_screen.dart was not found."
}

$backupPath = "$dashboardPath.before_offers.bak"

if (-not (Test-Path $backupPath)) {
    Copy-Item $dashboardPath $backupPath -Force
}

$content = [System.IO.File]::ReadAllText($dashboardPath)

$offersImport = "import '../offers/presentation/offers_screen.dart';"
$giftCardsImport = "import '../gift_cards/presentation/gift_cards_screen.dart';"

if (-not $content.Contains($offersImport)) {
    if (-not $content.Contains($giftCardsImport)) {
        throw "Gift cards import anchor was not found."
    }

    $content = $content.Replace(
        $giftCardsImport,
        "$giftCardsImport`r`n$offersImport"
    )
}

$cardStart = $content.IndexOf("icon: Icons.local_offer_outlined")

if ($cardStart -lt 0) {
    throw "Offers card was not found."
}

$nextCard = $content.IndexOf(
    "_buildMoreFeatureCard(",
    $cardStart + 1
)

if ($nextCard -lt 0) {
    throw "The next dashboard card was not found."
}

$segment = $content.Substring(
    $cardStart,
    $nextCard - $cardStart
)

if (-not $segment.Contains("OffersScreen(")) {
    $pattern = "onTap:\s*\(\)\s*=>\s*_showComingSoon\([^;]+;"

    $replacement = @"
onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OffersScreen(
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                },
"@

    $updatedSegment = [System.Text.RegularExpressions.Regex]::Replace(
        $segment,
        $pattern,
        $replacement,
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if ($updatedSegment -eq $segment) {
        throw "Offers card onTap handler was not found."
    }

    $content = $content.Substring(0, $cardStart) +
        $updatedSegment +
        $content.Substring($nextCard)
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText(
    $dashboardPath,
    $content,
    $utf8NoBom
)

Write-Host "Dashboard offers navigation patched successfully."
