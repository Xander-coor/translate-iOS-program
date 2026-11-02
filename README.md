# 即時翻譯（iPhone 網頁 App / PWA）

英↔中即時翻譯，單字到長文皆可。以 Claude 串流翻譯，停止輸入 0.6 秒後自動翻譯，譯文逐字出現。
提示詞要求使用當下母語人士口語／網路用語，並附上俚語、詞源與語氣說明；中文一律繁體（台灣用語）。

## 使用（不需要 Mac）
1. GitHub repo → Settings → Pages → Deploy from a branch，選此分支與 `/(root)`。
2. iPhone Safari 開啟 `https://<帳號>.github.io/translate-ios-program/`。
3. 分享 → 加入主畫面。
4. 首次開啟輸入 Anthropic API Key（只存在手機瀏覽器）。

## 注意
金鑰在瀏覽器端，僅適合自用；要分享給他人請改走後端代理。
