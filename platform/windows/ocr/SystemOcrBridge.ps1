param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    [string]$LanguageTag = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.Drawing

function Wait-WinRtOperation {
    param(
        [Parameter(Mandatory = $true)]$Operation,
        [Parameter(Mandatory = $true)][Type]$ResultType
    )

    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object {
            $_.Name -eq 'AsTask' -and
            $_.IsGenericMethod -and
            $_.GetParameters().Count -eq 1
        } |
        Select-Object -First 1
    $task = $asTask.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.Wait()
    return $task.Result
}

try {
    $resolvedPath = (Resolve-Path -LiteralPath $ImagePath).Path
    $ocrEngineType = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
    $engine = $null
    if (-not [string]::IsNullOrWhiteSpace($LanguageTag)) {
        try {
            $languageType = [Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime]
            $language = [Activator]::CreateInstance($languageType, @($LanguageTag))
            if ($ocrEngineType::IsLanguageSupported($language)) {
                $engine = $ocrEngineType::TryCreateFromLanguage($language)
            }
        } catch {
            $engine = $null
        }
    }
    if ($null -eq $engine) {
        $engine = $ocrEngineType::TryCreateFromUserProfileLanguages()
    }
    if ($null -eq $engine) {
        throw 'Windows OCR language pack is unavailable'
    }

    # Windows OCR loses small antialiased glyphs easily. Upscale the selected
    # region before decoding while staying under the engine's supported limit.
    # The original file remains untouched and continues to drive the UI preview.
    $recognitionPath = $resolvedPath
    $enhancedPath = $null
    $sourceImage = [System.Drawing.Image]::FromFile($resolvedPath)
    try {
        $maxDimension = [Math]::Min(2400, [int]$ocrEngineType::MaxImageDimension)
        $largestSide = [Math]::Max($sourceImage.Width, $sourceImage.Height)
        $scale = [Math]::Min(3.0, $maxDimension / [double]$largestSide)
        if ($scale -gt 1.08) {
            $targetWidth = [Math]::Max(1, [int][Math]::Round($sourceImage.Width * $scale))
            $targetHeight = [Math]::Max(1, [int][Math]::Round($sourceImage.Height * $scale))
            $enhanced = New-Object System.Drawing.Bitmap(
                $targetWidth, $targetHeight,
                [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            try {
                $graphics = [System.Drawing.Graphics]::FromImage($enhanced)
                try {
                    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
                    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                    $graphics.DrawImage($sourceImage, 0, 0, $targetWidth, $targetHeight)
                } finally {
                    $graphics.Dispose()
                }
                $enhancedPath = [System.IO.Path]::Combine(
                    [System.IO.Path]::GetTempPath(),
                    'lingust-ocr-enhanced-' + [Guid]::NewGuid().ToString('N') + '.png')
                $enhanced.Save($enhancedPath, [System.Drawing.Imaging.ImageFormat]::Png)
                $recognitionPath = $enhancedPath
            } finally {
                $enhanced.Dispose()
            }
        }
    } finally {
        $sourceImage.Dispose()
    }

    $storageFileType = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
    $file = Wait-WinRtOperation ($storageFileType::GetFileFromPathAsync($recognitionPath)) $storageFileType

    $streamType = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
    $accessModeType = [Windows.Storage.FileAccessMode, Windows.Storage, ContentType = WindowsRuntime]
    $stream = Wait-WinRtOperation ($file.OpenAsync($accessModeType::Read)) $streamType

    $decoderType = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
    $decoder = Wait-WinRtOperation ($decoderType::CreateAsync($stream)) $decoderType
    $softwareBitmapType = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
    $bitmap = Wait-WinRtOperation ($decoder.GetSoftwareBitmapAsync()) $softwareBitmapType

    $ocrResultType = [Windows.Media.Ocr.OcrResult, Windows.Foundation, ContentType = WindowsRuntime]
    $result = Wait-WinRtOperation ($engine.RecognizeAsync($bitmap)) $ocrResultType
    $lines = @()
    foreach ($line in $result.Lines) {
        $lines += [string]$line.Text
    }

    [ordered]@{
        ok = $true
        text = ($lines -join "`n").Trim()
        lines = $lines
    } | ConvertTo-Json -Compress -Depth 4

    if ($null -ne $bitmap) { $bitmap.Dispose() }
    if ($null -ne $stream) { $stream.Dispose() }
    if ($null -ne $enhancedPath -and (Test-Path -LiteralPath $enhancedPath)) {
        Remove-Item -LiteralPath $enhancedPath -Force
    }
    exit 0
} catch {
    if ($null -ne $enhancedPath -and (Test-Path -LiteralPath $enhancedPath)) {
        Remove-Item -LiteralPath $enhancedPath -Force -ErrorAction SilentlyContinue
    }
    [ordered]@{
        ok = $false
        error = $_.Exception.Message
    } | ConvertTo-Json -Compress
    exit 1
}
