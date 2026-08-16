param(
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\Media')
)

Add-Type -AssemblyName System.Drawing

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
[System.IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null

for ($level = 1; $level -le 20; $level++) {
    $bitmap = [System.Drawing.Bitmap]::new(128, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, [single]($level * 2))
    try {
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $inset = [single]($level + 1)
        $diameter = [single](128 - (2 * $inset))
        $graphics.DrawEllipse($pen, $inset, $inset, $diameter, $diameter)
        $fileName = 'Ring{0:D2}.png' -f $level
        $bitmap.Save((Join-Path $resolvedOutput $fileName), [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $pen.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}
