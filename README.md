# BingRunner

簡單的 Windows Edge 關鍵字搜尋工具。

## 最新版本

`v2.0.0` 已改寫為 C# Windows Forms，不再包含 AutoHotkey 編譯器。程式可在 Windows 11 直接執行，並已使用 Microsoft Defender 掃描，未發現威脅。

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

1. 從 Releases 下載 `BingRunner-v2.0.0-win-x64.zip`。
2. 解壓縮。
3. 開啟 Microsoft Edge。
4. 執行 `BingRunner.exe`。
5. 選擇搜尋次數與詞庫來源，再按「開始」。

使用「自訂 TXT」或「混合」時，可將 `keywords.txt` 放在 EXE 同一資料夾；每行填寫一個關鍵字。

## 原始碼

目前版本使用 C# Windows Forms。舊版 `BingRunner.ahk` 僅供版本參考。
