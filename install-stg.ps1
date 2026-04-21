# Blaze CLI (staging, 社内向け) installer for Windows
# 使い方: irm https://cli.igness.ai/install-stg.ps1 | iex
$ErrorActionPreference = 'Stop'

$repo = 'igness-ai/blaze-cli-dist'
$installDir = Join-Path $env:USERPROFILE '.blaze-stg\bin'
$binaryName = 'blaze-stg.exe'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Arch {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        'AMD64' { 'x86_64' }
        'ARM64' { 'aarch64' }
        default { throw "unsupported architecture: $env:PROCESSOR_ARCHITECTURE" }
    }
}

$arch = Get-Arch
$target = "${arch}-pc-windows-msvc"

# 最新 staging tag (stg-*) を取得
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/${repo}/releases?per_page=10"
$stg = $releases | Where-Object { $_.tag_name -like 'stg-*' } | Sort-Object tag_name -Descending | Select-Object -First 1
if (-not $stg) { throw "staging release が見つかりません" }
$tag = $stg.tag_name
$assetBase = "blaze-stg-${target}"
$archiveName = "${assetBase}.zip"
$checksumName = "${archiveName}.sha256"

$asset = $stg.assets | Where-Object { $_.name -eq $archiveName } | Select-Object -First 1
$checksum = $stg.assets | Where-Object { $_.name -eq $checksumName } | Select-Object -First 1
if (-not $asset -or -not $checksum) { throw "アセットが見つかりません: $archiveName" }

Write-Host "Installing Blaze CLI staging ($tag, $target)..."

$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $zipPath = Join-Path $tmp $archiveName
    $sumPath = Join-Path $tmp $checksumName

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
    Invoke-WebRequest -Uri $checksum.browser_download_url -OutFile $sumPath -UseBasicParsing

    $expected = ((Get-Content $sumPath -Raw).Trim() -split '\s+')[0].ToLower()
    $actual = (Get-FileHash -Algorithm SHA256 $zipPath).Hash.ToLower()
    if ($expected -ne $actual) {
        throw "SHA-256 不一致: expected=$expected actual=$actual"
    }

    Expand-Archive -Path $zipPath -DestinationPath $tmp -Force
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }

    $targetPath = Join-Path $installDir $binaryName
    if (Test-Path $targetPath) { Move-Item -Path $targetPath -Destination "$targetPath.bak" -Force }
    # アーカイブ内のバイナリは "blaze.exe" 名 (CI で固定)
    Move-Item -Path (Join-Path $tmp 'blaze.exe') -Destination $targetPath -Force
    if (Test-Path "$targetPath.bak") { Remove-Item "$targetPath.bak" -Force }

    Write-Host "Installed to $targetPath"

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*${installDir}*") {
        [Environment]::SetEnvironmentVariable('Path', "${userPath};${installDir}", 'User')
        Write-Host "Added $installDir to User PATH. 新しいターミナルを開いてください。"
    }

    Write-Host ''
    Write-Host "Run 'blaze-stg' to get started."
} finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
