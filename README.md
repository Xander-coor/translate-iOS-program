# 即時翻譯（iOS，SwiftUI）

英↔中即時翻譯，單字到長文皆可。以 Claude 串流翻譯，譯文隨生成逐字出現；停止輸入 0.6 秒後自動翻譯。
提示詞要求使用當下母語人士口語／網路用語，並附上俚語、詞源與語氣說明；中文一律繁體（台灣用語）。

## 功能
- 自動偵測中／英方向（也可手動切換）
- 即時串流譯文、備註（用語、詞源、例句、其他說法）
- 朗讀、複製、一鍵把譯文反向翻回
- API Key 存於 Keychain

## 建置（需 macOS + Xcode 15+）
```
brew install xcodegen
xcodegen        # 由 project.yml 產生 Translate.xcodeproj
open Translate.xcodeproj
```
執行後在設定輸入 Anthropic API Key。模型可於 `ClaudeClient.model` 調整。

## 注意
- 上架前請改走自己的後端代理，避免金鑰放在 App 內。
- 「最新」程度取決於模型知識；若需即時網路新詞，可在後端加入 web search 工具。

## 只有 iPhone（沒有 Mac）：用網頁版 PWA
`web/index.html` 是功能相同的單檔網頁版。
1. GitHub repo → Settings → Pages → Source 選 Deploy from a branch，選此分支（或合併後的 main）與 `/web` 資料夾（若只提供 `/(root)`，可把 `index.html` 複製到根目錄）。
2. 用 iPhone Safari 開啟 `https://<帳號>.github.io/translate-ios-program/`。
3. 分享 → 加入主畫面，之後就像 App 一樣開啟。
4. 首次開啟輸入 Anthropic API Key（只存在手機瀏覽器）。
