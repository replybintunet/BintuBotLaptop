#!/bin/bash
BOT_TOKEN="7608676743:AAE7cE882C8jGhjjoV7XtXFexegGIaZHJi8"
CHAT_ID="7038128289"
if [ ! -d "$HOME/BintuBot" ]; then git clone https://github.com/replybintunet/BintuBot.git "$HOME/BintuBot"; fi
cd "$HOME/BintuBot" || exit
npm install
npm run dev &
cloudflared tunnel --url http://localhost:5000 --logfile cf.log --loglevel info &
sleep 10
CF_URL=$(grep -oP 'https://[a-z0-9\-]+\.trycloudflare\.com' cf.log | tail -n1)
if [ -n "$CF_URL" ]; then
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" -d text="✅ BintuBot is live: ${CF_URL}" -d parse_mode="Markdown"
else
  echo "❌ Failed to extract Cloudflare URL."
fi
wait