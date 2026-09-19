# BingRunner

簡單的 AutoHotkey v2 Edge 關鍵字搜尋工具。

## 功能

- 自訂搜尋次數，預設 22 次
- 每次搜尋前自動切換至 Microsoft Edge
- 只在網址列輸入關鍵字，不組合搜尋網址
- 8.5～10 秒隨機間隔
- 支援開始、暫停、繼續及停止
- 詞庫來源可選「混合」、「線上熱門詞」或「自訂 TXT」
- 線上新聞詞會清除 RSS／CDATA 標記並限制為 10 個字
- 找不到 `keywords.txt` 時會自動建立範本

## 使用方式

1. 下載 `BingRunner.exe`。
2. 開啟 Microsoft Edge。
3. 執行 `BingRunner.exe`。
4. 選擇搜尋次數與詞庫來源，再按「開始」。

使用「自訂 TXT」或「混合」時，可將 `keywords.txt` 放在 EXE 同一資料夾；每行填寫一個關鍵字。

## 原始碼

`BingRunner.ahk` 使用 AutoHotkey v2。
