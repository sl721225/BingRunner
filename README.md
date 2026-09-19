# BingRunner

簡單的 C# Windows 瀏覽器關鍵字搜尋工具，支援 Microsoft Edge 與 Google Chrome。

## 最新版本

`v2.1.0` 使用 C# Windows Forms 製作，可在 Windows 11 直接執行。

## 重要提醒

程式會將關鍵字輸入瀏覽器網址列。若要執行 Bing 搜尋，請先將 Edge 或 Chrome 的預設搜尋引擎設定為 Bing。

## 功能

- 目標瀏覽器可選「自動偵測」、「Microsoft Edge」或「Google Chrome」
- 每次搜尋前自動切換並聚焦目標瀏覽器
- 自訂搜尋次數，預設 22 次
- 只在網址列輸入關鍵字，不組合搜尋網址
- 8.5～10 秒隨機間隔
- 支援開始、暫停、繼續及停止
- 快捷鍵：F8 開始、F9 暫停／繼續、F10 停止
- 詞庫來源可選「混合」、「線上熱門詞」或「自訂 TXT」
- 線上新聞詞會清除 RSS／CDATA 標記並限制為 10 個字
- 找不到 `keywords.txt` 時會自動建立範本

## 使用方式

1. 從 Releases 下載 `BingRunner-v2.1.0-win-x64.zip`。
2. 解壓縮。
3. 開啟 Microsoft Edge 或 Google Chrome。
4. 執行 `BingRunner.exe`。
5. 選擇目標瀏覽器、搜尋次數與詞庫來源，再按「開始」。

使用「自訂 TXT」或「混合」時，可將 `keywords.txt` 放在 EXE 同一資料夾；每行填寫一個關鍵字。
