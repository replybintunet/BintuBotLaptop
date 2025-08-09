# BintuBot Startup Script for Windows (PowerShell)
# -----------------------------------------------
# Prerequisites (install manually before running):
# - Node.js LTS: https://nodejs.org/
# - FFmpeg: https://ffmpeg.org/download.html
# - Cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation
# - Git: https://git-scm.com/download/win

# Telegram bot credentials
$BOT_TOKEN = "7608676743:AAE7cE882C8jGhjjoV7XtXFexegGIaZHJi8"
$CHAT_ID   = "7038128289"

# Paths
$RepoPath = "$HOME\BintuBot"
$CloudflaredLog = "$RepoPath\cf.log"

# Clone repo if missing
if (-not (Test-Path $RepoPath)) {
    Write-Host "📥 Cloning BintuBot repository..."
    git clone https://github.com/replybintunet/BintuBot.git $RepoPath
}
Set-Location $RepoPath

# Install Node.js packages
Write-Host "📦 Installing dependencies..."
npm install

# Start Node.js backend in background
Write-Host "🚀 Starting Node.js backend..."
$nodeProcess = Start-Process -FilePath "npm" -ArgumentList "run dev" -NoNewWindow -PassThru

# Start Cloudflared tunnel in background with log file
Write-Host "🌐 Starting Cloudflare Tunnel..."
$cloudflaredProcess = Start-Process -FilePath "cloudflared" `
    -ArgumentList "tunnel --url http://localhost:5000 --logfile `"$CloudflaredLog`" --loglevel info" `
    -NoNewWindow -PassThru

# Wait and poll for Cloudflare URL from log (max 10 tries)
$maxTries = 10
$tries = 0
$CF_URL = $null

while (-not $CF_URL -and $tries -lt $maxTries) {
    Start-Sleep -Seconds 3
    $tries++
    if (Test-Path $CloudflaredLog) {
        $logContent = Get-Content $CloudflaredLog -Raw
        $matches = [regex]::Matches($logContent, "https://[a-z0-9\-]+\.trycloudflare\.com")
        if ($matches.Count -gt 0) {
            $CF_URL = $matches[$matches.Count - 1].Value
        }
    }
}

if ($CF_URL) {
    Write-Host "✅ BintuBot is live at $CF_URL"
    # Send Telegram notification
    Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" `
        -Method Post `
        -Body @{ chat_id = $CHAT_ID; text = "✅ BintuBot is now live: $CF_URL"; parse_mode = "Markdown" }
} else {
    Write-Host "❌ Failed to extract Cloudflare URL from log."
}

# Keep script alive while both processes run
Write-Host "🛑 Press Ctrl+C to stop the bot and tunnel."
while (-not $nodeProcess.HasExited -and -not $cloudflaredProcess.HasExited) {
    Start-Sleep -Seconds 5
}
Write-Host "Processes exited, script ending."
