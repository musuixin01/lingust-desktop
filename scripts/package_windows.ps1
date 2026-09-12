[CmdletBinding()]
param(
    [string]$BuildDir = "build",
    [string]$QtBin = "D:\DevTools\QT\6.11.2\mingw_64\bin",
    [string]$ToolchainBin = "D:\DevTools\QT\Tools\mingw1310_64\bin",
    [switch]$InstallPackagingTool,
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildPath = Join-Path $projectRoot $BuildDir
$cmake = "D:\DevTools\QT\Tools\CMake_64\bin\cmake.exe"
$ninja = "D:\DevTools\QT\Tools\Ninja"
$deployTool = Join-Path $QtBin "windeployqt.exe"

if (-not (Test-Path -LiteralPath $cmake)) { $cmake = (Get-Command cmake -ErrorAction Stop).Source }
if (-not (Test-Path -LiteralPath $deployTool)) { throw "找不到 windeployqt：$deployTool" }

$cmakeText = Get-Content -LiteralPath (Join-Path $projectRoot "CMakeLists.txt") -Raw
if ($cmakeText -notmatch 'project\(lingust VERSION ([0-9]+\.[0-9]+\.[0-9]+)') {
    throw "无法从 CMakeLists.txt 读取版本号"
}
$version = $Matches[1]
$artifactRoot = Join-Path $projectRoot "artifacts"
$stagePath = Join-Path $artifactRoot "Linguist-$version-win64"
$binaryPath = Join-Path $buildPath "bin\lingust.exe"

if (-not $SkipBuild) {
    if (-not (Test-Path -LiteralPath $ToolchainBin)) { throw "找不到 MinGW 工具链：$ToolchainBin" }
    $env:PATH = "$ninja;$ToolchainBin;$QtBin;" + $env:PATH
    & $cmake --build $buildPath --config Release --parallel 1
    if ($LASTEXITCODE -ne 0) { throw "Release 构建失败" }
}
if (-not (Test-Path -LiteralPath $binaryPath)) { throw "找不到程序：$binaryPath" }

if (Test-Path -LiteralPath $stagePath) { Remove-Item -LiteralPath $stagePath -Recurse -Force }
New-Item -ItemType Directory -Path $stagePath -Force | Out-Null
Copy-Item -LiteralPath $binaryPath -Destination $stagePath
Copy-Item -LiteralPath (Join-Path $buildPath "bin\SystemMediaBridge.ps1") -Destination $stagePath
Copy-Item -LiteralPath (Join-Path $buildPath "bin\SystemOcrBridge.ps1") -Destination $stagePath
Copy-Item -LiteralPath (Join-Path $projectRoot "resources\app.ico") -Destination $stagePath

& $deployTool --release --compiler-runtime --no-translations --qmldir (Join-Path $projectRoot "ui") --dir $stagePath $binaryPath
if ($LASTEXITCODE -ne 0) { throw "Qt 运行库收集失败" }

$docStage = Join-Path $stagePath "docs"
New-Item -ItemType Directory -Path $docStage -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot "README.md") -Destination $stagePath
Copy-Item -LiteralPath (Join-Path $projectRoot "LICENSE") -Destination $stagePath
Copy-Item -LiteralPath (Join-Path $projectRoot "docs\RELEASE.md") -Destination $docStage
Copy-Item -LiteralPath (Join-Path $projectRoot "docs\RELEASE_NOTES_0.1.0.md") -Destination $docStage
Copy-Item -LiteralPath (Join-Path $projectRoot "docs\VALIDATION.md") -Destination $docStage

$compilerCandidates = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe",
    "C:\Program Files\Inno Setup 7\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $compiler -and $InstallPackagingTool) {
    & winget install --id JRSoftware.InnoSetup.7 -e -s winget --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup 安装失败" }
    $compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $compiler) {
    throw "未找到 Inno Setup。首次运行请增加 -InstallPackagingTool。"
}

$installerScript = Join-Path $projectRoot "installer\Linguist.iss"
& $compiler "/DSourceDir=$stagePath" "/DOutputDir=$artifactRoot" "/DAppVersion=$version" $installerScript
if ($LASTEXITCODE -ne 0) { throw "安装包生成失败" }

$installerPath = Join-Path $artifactRoot "Linguist-Setup-$version-win64.exe"
if (-not (Test-Path -LiteralPath $installerPath)) { throw "未生成预期安装包：$installerPath" }
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $installerPath).Hash
Set-Content -LiteralPath "$installerPath.sha256" -Encoding ascii -Value "$hash  $(Split-Path -Leaf $installerPath)"
Write-Output "Installer: $installerPath"
Write-Output "SHA256: $hash"
