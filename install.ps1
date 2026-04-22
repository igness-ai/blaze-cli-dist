# Blaze CLI (production) installer for Windows
# 使い方: irm https://cli.igness.ai/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$repo = 'igness-ai/blaze-cli-dist'
$installDir = Join-Path $env:USERPROFILE '.blaze\bin'
$binaryName = 'blaze.exe'

# TLS 1.2 強制 (PowerShell 5.1 のデフォルト TLS 1.0 を引き上げ)
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

# 最新 production tag を取得
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/${repo}/releases/latest"
$version = $release.tag_name.TrimStart('v')
$assetBase = "blaze-v${version}-${target}"
$archiveName = "${assetBase}.zip"
$checksumName = "${archiveName}.sha256"

$asset = $release.assets | Where-Object { $_.name -eq $archiveName } | Select-Object -First 1
$checksum = $release.assets | Where-Object { $_.name -eq $checksumName } | Select-Object -First 1
if (-not $asset -or -not $checksum) { throw "アセットが見つかりません: $archiveName" }

Write-Host "Installing Blaze CLI v${version} (${target})..."

$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().Guid)
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $zipPath = Join-Path $tmp $archiveName
    $sumPath = Join-Path $tmp $checksumName

    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
    Invoke-WebRequest -Uri $checksum.browser_download_url -OutFile $sumPath -UseBasicParsing

    # SHA-256 検証 (失敗時は fail-fast)
    $expected = ((Get-Content $sumPath -Raw).Trim() -split '\s+')[0].ToLower()
    $actual = (Get-FileHash -Algorithm SHA256 $zipPath).Hash.ToLower()
    if ($expected -ne $actual) {
        throw "SHA-256 不一致: expected=$expected actual=$actual"
    }

    Expand-Archive -Path $zipPath -DestinationPath $tmp -Force
    if (-not (Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir | Out-Null }

    $target = Join-Path $installDir $binaryName
    if (Test-Path $target) { Move-Item -Path $target -Destination "$target.bak" -Force }
    Move-Item -Path (Join-Path $tmp 'blaze.exe') -Destination $target -Force
    if (Test-Path "$target.bak") { Remove-Item "$target.bak" -Force }

    Write-Host "Installed to $target"

    # User PATH 追加
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $isJa = (Get-Culture).Name -like 'ja*'
    if ($userPath -notlike "*${installDir}*") {
        [Environment]::SetEnvironmentVariable('Path', "${userPath};${installDir}", 'User')
        if ($isJa) {
            Write-Host "$installDir を User PATH に追加しました"
        } else {
            Write-Host "Added $installDir to User PATH"
        }
    }

    Write-Host ''
    if ($isJa) {
        Write-Host "新規ターミナルを開いて 'blaze' コマンドを実行してください"
    } else {
        Write-Host "Open a new terminal and run the 'blaze' command"
    }
} finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
