$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$outDir = "C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\premium_promos"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$items = @(
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579301762.png'; Text = 'Give, Share & Connect'; Grad='linear-gradient(135deg, #1A2980 0%, #26D0CE 100%)' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579326833.png'; Text = 'Find Items Near You'; Grad='linear-gradient(135deg, #4b6cb7 0%, #182848 100%)' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579366016.png'; Text = 'List Donations in Seconds'; Grad='linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%)' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579416805.png'; Text = 'Full Control & Safety'; Grad='linear-gradient(135deg, #114357 0%, #F29492 100%)' },
    @{ Path = 'C:\Users\HP\.gemini\antigravity-ide\brain\7e5e11cf-1a67-4dc3-a16a-e9d4980b93d3\media__1781579430796.png'; Text = 'Secure & Reliable Platform'; Grad='linear-gradient(135deg, #2c3e50 0%, #3498db 100%)' }
)

$index = 1
foreach ($item in $items) {
    $imgPath = "file:///" + $item.Path.Replace('\', '/')
    $text = $item.Text
    $grad = $item.Grad
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@700&display=swap" rel="stylesheet">
<style>
    body {
        margin: 0; padding: 0;
        width: 1242px; height: 2208px;
        background: $grad;
        font-family: 'Poppins', sans-serif;
        display: flex; flex-direction: column; align-items: center;
        overflow: hidden;
    }
    
    .title-container {
        margin-top: 250px;
        margin-bottom: 120px;
        text-align: center;
        padding: 0 50px;
        z-index: 5;
    }

    h1 {
        font-size: 95px;
        color: white;
        margin: 0;
        line-height: 1.2;
        text-shadow: 0 20px 40px rgba(0,0,0,0.4);
    }

    .phone {
        position: relative;
        width: 950px;
        height: 1950px;
        background: #000;
        border-radius: 75px;
        border: 22px solid #111;
        box-shadow: 
            0 60px 120px rgba(0,0,0,0.7),
            inset 0 0 15px rgba(255,255,255,0.2),
            inset 0 0 25px rgba(255,255,255,0.1);
        box-sizing: border-box;
        z-index: 5;
    }

    .screen {
        width: 100%;
        height: 100%;
        border-radius: 52px;
        overflow: hidden;
        background: white;
        position: relative;
    }

    .screen img {
        width: 100%;
        height: auto;
        display: block;
    }

    .notch {
        position: absolute;
        top: 0;
        left: 50%;
        transform: translateX(-50%);
        width: 260px;
        height: 45px;
        background: #111;
        border-bottom-left-radius: 25px;
        border-bottom-right-radius: 25px;
        z-index: 10;
    }
    
    .blob {
        position: absolute;
        filter: blur(150px);
        opacity: 0.6;
        z-index: 0;
    }
    .blob1 { top: 15%; left: 5%; width: 700px; height: 700px; background: rgba(255, 255, 255, 0.3); border-radius: 50%; }
    .blob2 { bottom: -5%; right: -5%; width: 900px; height: 900px; background: rgba(0, 255, 200, 0.2); border-radius: 50%; }

</style>
</head>
<body>
    <div class="blob blob1"></div>
    <div class="blob blob2"></div>

    <div class="title-container">
        <h1>$text</h1>
    </div>

    <div class="phone">
        <div class="notch"></div>
        <div class="screen">
            <img src="$imgPath" alt="screenshot">
        </div>
    </div>
</body>
</html>
"@
    
    $htmlPath = "$outDir\temp_$index.html"
    Set-Content $htmlPath -Value $html -Encoding UTF8
    
    $outImg = "$outDir\premium_$index.png"
    Start-Process -FilePath $chrome -ArgumentList "--headless --disable-gpu --screenshot=`"$outImg`" --window-size=1242,2208 `"$htmlPath`"" -Wait -NoNewWindow
    
    Write-Host "Generated $outImg"
    $index++
}
