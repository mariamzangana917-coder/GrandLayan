$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Backup-File {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    $backupPath = "$Path.before_gift_cards_fix.bak"

    if (-not (Test-Path $backupPath)) {
        Copy-Item $Path $backupPath -Force
    }
}

$giftCardService = Join-Path `
    $projectRoot `
    "lib\features\gift_cards\data\gift_card_service.dart"

$giftCardsScreen = Join-Path `
    $projectRoot `
    "lib\features\gift_cards\presentation\gift_cards_screen.dart"

$categoryScreen = Join-Path `
    $projectRoot `
    "lib\features\catalog\categories\category_management_screen.dart"

Backup-File -Path $giftCardService
Backup-File -Path $giftCardsScreen
Backup-File -Path $categoryScreen

if (Test-Path $giftCardService) {
    $content = [System.IO.File]::ReadAllText($giftCardService)

    $oldBlock = @"
      final response = await ApiClient.dio.get(
        _path,
        queryParameters: {if (isActive != null) 'is_active': isActive},
      );
"@

    $newBlock = @"
      final queryParameters = <String, dynamic>{};

      if (isActive != null) {
        queryParameters['is_active'] = isActive;
      }

      final response = await ApiClient.dio.get(
        _path,
        queryParameters: queryParameters,
      );
"@

    if ($content.Contains($oldBlock)) {
        $content = $content.Replace($oldBlock, $newBlock)
        [System.IO.File]::WriteAllText(
            $giftCardService,
            $content,
            (New-Object System.Text.UTF8Encoding($false))
        )
    }
}

foreach ($path in @($giftCardsScreen, $categoryScreen)) {
    if (-not (Test-Path $path)) {
        continue
    }

    $content = [System.IO.File]::ReadAllText($path)

    $content = $content.Replace(
        "(_, __, ___)",
        "(_, _, _)"
    )

    $content = $content.Replace(
        "(_, __)",
        "(_, _)"
    )

    [System.IO.File]::WriteAllText(
        $path,
        $content,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

Write-Host "Gift Cards compile fixes applied successfully."
