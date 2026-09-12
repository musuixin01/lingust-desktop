param(
    [ValidateSet('Watch', 'Play', 'Pause', 'Toggle', 'Next', 'Previous', 'Seek')]
    [string]$Action = 'Watch',
    [int]$PositionSeconds = 0
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.Drawing

function Convert-ToCircularPng {
    param([byte[]]$Bytes)

    $input = New-Object System.IO.MemoryStream(, $Bytes)
    $source = [System.Drawing.Image]::FromStream($input)
    $size = 256
    $bitmap = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(0, 0, $size, $size)
    $graphics.SetClip($path)
    $scale = [Math]::Max($size / $source.Width, $size / $source.Height)
    $drawWidth = [int][Math]::Ceiling($source.Width * $scale)
    $drawHeight = [int][Math]::Ceiling($source.Height * $scale)
    $graphics.DrawImage($source, [int](($size - $drawWidth) / 2), [int](($size - $drawHeight) / 2), $drawWidth, $drawHeight)
    $output = New-Object System.IO.MemoryStream
    $bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
    $result = $output.ToArray()
    $output.Dispose()
    $path.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
    $source.Dispose()
    $input.Dispose()
    return $result
}

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

function Get-SessionManager {
    $managerType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime]
    return Wait-WinRtOperation ($managerType::RequestAsync()) $managerType
}

function Invoke-SessionAction {
    param($Session, [string]$RequestedAction)

    if ($null -eq $Session) { return }
    switch ($RequestedAction) {
        'Play'     { [void](Wait-WinRtOperation ($Session.TryPlayAsync()) ([bool])) }
        'Pause'    { [void](Wait-WinRtOperation ($Session.TryPauseAsync()) ([bool])) }
        'Toggle'   { [void](Wait-WinRtOperation ($Session.TryTogglePlayPauseAsync()) ([bool])) }
        'Next'     { [void](Wait-WinRtOperation ($Session.TrySkipNextAsync()) ([bool])) }
        'Previous' { [void](Wait-WinRtOperation ($Session.TrySkipPreviousAsync()) ([bool])) }
        'Seek' {
            $ticks = [Math]::Max(0, $PositionSeconds) * 10000000L
            [void](Wait-WinRtOperation ($Session.TryChangePlaybackPositionAsync($ticks)) ([bool]))
        }
    }
}

function Get-SessionSnapshot {
    param($Session)

    if ($null -eq $Session) {
        return [ordered]@{
            connected = $false
            playing = $false
            title = ''
            artist = ''
            album = ''
            sourceAppId = ''
            durationSeconds = 0
            positionSeconds = 0
        }
    }

    $mediaType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media.Control, ContentType = WindowsRuntime]
    $media = Wait-WinRtOperation ($Session.TryGetMediaPropertiesAsync()) $mediaType
    $coverKey = "{0}`n{1}`n{2}" -f $media.Title, $media.Artist, $media.AlbumTitle
    if ($script:coverKey -ne $coverKey) {
        $script:coverKey = $coverKey
        $script:coverDataUrl = ''
        if ($null -ne $media.Thumbnail) {
            try {
                $streamType = [Windows.Storage.Streams.IRandomAccessStreamWithContentType, Windows.Storage.Streams, ContentType = WindowsRuntime]
                $randomStream = Wait-WinRtOperation ($media.Thumbnail.OpenReadAsync()) $streamType
                $randomAccessType = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
                $getInputStream = $randomAccessType.GetMethod('GetInputStreamAt')
                $inputStream = $getInputStream.Invoke($randomStream, @([UInt64]0))
                $netStream = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($inputStream)
                $memory = New-Object System.IO.MemoryStream
                $netStream.CopyTo($memory)
                $coverBytes = Convert-ToCircularPng $memory.ToArray()
                $script:coverDataUrl = 'data:image/png;base64,' + [Convert]::ToBase64String($coverBytes)
                $memory.Dispose()
                $netStream.Dispose()
            } catch {
                                $script:coverDataUrl = ''
            }
        }
    }
    $playback = $Session.GetPlaybackInfo()
    $timeline = $Session.GetTimelineProperties()
    return [ordered]@{
        connected = $true
        playing = $playback.PlaybackStatus.ToString() -eq 'Playing'
        title = [string]$media.Title
        artist = [string]$media.Artist
        album = [string]$media.AlbumTitle
        sourceAppId = [string]$Session.SourceAppUserModelId
        coverDataUrl = [string]$script:coverDataUrl
        durationSeconds = [Math]::Max(0, [int][Math]::Round(($timeline.EndTime - $timeline.StartTime).TotalSeconds))
        positionSeconds = [Math]::Max(0, [int][Math]::Round(($timeline.Position - $timeline.StartTime).TotalSeconds))
    }
}

try {
    $manager = Get-SessionManager
    if ($Action -ne 'Watch') {
        Invoke-SessionAction $manager.GetCurrentSession() $Action
        exit 0
    }

    $lastJson = ''
    while ($true) {
        try {
            $json = Get-SessionSnapshot $manager.GetCurrentSession() | ConvertTo-Json -Compress
        } catch {
            $json = ([ordered]@{ connected = $false; playing = $false; error = $_.Exception.Message } | ConvertTo-Json -Compress)
        }
        if ($json -ne $lastJson) {
            [Console]::Out.WriteLine($json)
            [Console]::Out.Flush()
            $lastJson = $json
        }
        Start-Sleep -Milliseconds 500
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
