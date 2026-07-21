Add-Type -AssemblyName System.Drawing

$outDir = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\promo_screenshots'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$images = @(
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579301762.png'; Text = 'Give, Share & Connect' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579326833.png'; Text = 'Find Items Near You' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579366016.png'; Text = 'List Donations in Seconds' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579416805.png'; Text = 'Full Control & Safety' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579430796.png'; Text = 'Secure & Reliable Platform' }
)

[int]$width = 1242
[int]$height = 2208

$font = New-Object System.Drawing.Font('Segoe UI', 65, [System.Drawing.FontStyle]::Bold)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 0, 0))
$blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 20, 20, 20))

$rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
$c1 = [System.Drawing.Color]::FromArgb(255, 4, 180, 180)
$c2 = [System.Drawing.Color]::FromArgb(255, 15, 60, 120)
$gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)

[int]$index = 1
foreach ($item in $images) {
    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # Draw Background
    $g.FillRectangle($gradient, $rect)

    # Text coordinates
    [int]$textY = 180
    [int]$rectHeight = 250
    $textRect = New-Object System.Drawing.RectangleF(0, $textY, $width, $rectHeight)
    $shadowRect = New-Object System.Drawing.RectangleF(5, ($textY + 5), $width, $rectHeight)

    $g.DrawString($item.Text, $font, $shadowBrush, $shadowRect, $format)
    $g.DrawString($item.Text, $font, $textBrush, $textRect, $format)

    if (Test-Path $item.Path) {
        $srcImg = [System.Drawing.Image]::FromFile($item.Path)
        
        [int]$targetW = 900
        [double]$ratio = $srcImg.Height / $srcImg.Width
        [int]$targetH = [int]($targetW * $ratio)
        
        [int]$x = [int](($width - $targetW) / 2)
        [int]$y = 450
        
        [int]$bezelThickness = 22
        [int]$bezelX = $x - $bezelThickness
        [int]$bezelY = $y - $bezelThickness
        [int]$bezelW = $targetW + ($bezelThickness * 2)
        [int]$bezelH = $targetH + ($bezelThickness * 2)

        $bezelRect = New-Object System.Drawing.Rectangle($bezelX, $bezelY, $bezelW, $bezelH)
        
        [int]$shadowX = $bezelX - 10
        [int]$shadowY = $bezelY - 10
        [int]$shadowW = $bezelW + 20
        [int]$shadowH = $bezelH + 20
        $shadowRectFill = New-Object System.Drawing.Rectangle($shadowX, $shadowY, $shadowW, $shadowH)
        
        $g.FillRectangle($shadowBrush, $shadowRectFill)
        $g.FillRectangle($blackBrush, $bezelRect)
        
        $g.DrawImage($srcImg, $x, $y, $targetW, $targetH)
        
        $srcImg.Dispose()
    }
    
    $outFile = Join-Path $outDir "promo_$index.png"
    $bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    $index++
}

$font.Dispose()
$textBrush.Dispose()
$shadowBrush.Dispose()
$gradient.Dispose()
$format.Dispose()
$blackBrush.Dispose()
