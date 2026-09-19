#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; 🔎 Search Runner v1.1
; AutoHotkey v2
;
; 功能：
; - 預設搜尋 22 次
; - 可自訂搜尋次數
; - 100 個關鍵字
; - 前 100 次不重複
; - 每次搜尋前主動聚焦 Microsoft Edge
; - Ctrl+L → 純關鍵字 → Enter
; - 搜尋間隔 8.5～10 秒
; - 浮動 GUI
; - 即時進度
; - 倒數計時
; - 暫停 / 繼續
; - 停止
;
; 快捷鍵：
; F8  = 開始
; F9  = 暫停 / 繼續
; F10 = 停止
; ============================================================


; ============================================================
; ⚙️ 基本設定
; ============================================================

DEFAULT_COUNT := 22

MIN_DELAY := 8500
MAX_DELAY := 10000

EDGE_EXE := "ahk_exe msedge.exe"

; 混合詞庫設定：線上熱門詞 + 使用者自訂 keywords.txt
CUSTOM_KEYWORDS_FILE := A_ScriptDir "\keywords.txt"
ONLINE_KEYWORD_FEEDS := [
    "https://trends.google.com/trending/rss?geo=TW",
    "https://news.google.com/rss?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
    "https://tw.news.yahoo.com/rss"
]


; ============================================================
; 🌐 全域狀態
; ============================================================

global Running := false
global Paused := false

global Current := 0
global Total := DEFAULT_COUNT

global KeywordQueue := []
global CurrentKeyword := ""

global RemainingMs := 0
global SourceMode := "混合"


; ============================================================
; 🔎 100 個關鍵字
; ============================================================

global Keywords := [

    ; ===== 台灣 / 新聞 =====

    "台灣天氣",
    "今日新聞",
    "台灣新聞",
    "桃園天氣",
    "台北天氣",
    "高雄天氣",
    "台中天氣",
    "颱風最新消息",
    "地震最新消息",
    "中央氣象署",


    ; ===== 台灣旅遊 =====

    "桃園景點",
    "台北景點",
    "新北景點",
    "台中景點",
    "台南景點",
    "高雄景點",
    "宜蘭景點",
    "花蓮景點",
    "台東景點",
    "澎湖景點",


    ; ===== 台灣美食 =====

    "桃園美食",
    "台北美食",
    "台中美食",
    "台南美食",
    "高雄美食",
    "基隆美食",
    "新竹美食",
    "嘉義美食",
    "宜蘭美食",
    "花蓮美食",


    ; ===== 交通 =====

    "台灣高鐵",
    "台鐵時刻表",
    "高速公路路況",
    "桃園機場",
    "台北捷運",
    "桃園捷運",
    "台中捷運",
    "高雄捷運",
    "台灣公車",
    "國道即時路況",


    ; ===== 日本 =====

    "日本旅遊",
    "東京旅遊",
    "大阪旅遊",
    "京都旅遊",
    "北海道旅遊",
    "沖繩旅遊",
    "福岡旅遊",
    "廣島旅遊",
    "東京景點",
    "大阪景點",


    ; ===== 國際旅遊 =====

    "韓國旅遊",
    "首爾旅遊",
    "釜山旅遊",
    "泰國旅遊",
    "曼谷旅遊",
    "新加坡旅遊",
    "馬來西亞旅遊",
    "越南旅遊",
    "香港旅遊",
    "澳門旅遊",


    ; ===== 科技 =====

    "人工智慧",
    "科技新聞",
    "手機推薦",
    "筆電推薦",
    "電腦組裝",
    "Windows 11",
    "Android 手機",
    "iPhone 最新消息",
    "AI 最新消息",
    "電動車最新消息",


    ; ===== 財經 =====

    "台灣股市",
    "台股今日行情",
    "美國股市",
    "美元匯率",
    "日幣匯率",
    "黃金價格",
    "國際油價",
    "房價趨勢",
    "ETF 投資",
    "財經新聞",


    ; ===== 生活 =====

    "電影推薦",
    "Netflix 推薦",
    "動畫推薦",
    "咖啡推薦",
    "甜點推薦",
    "蛋黃酥做法",
    "鳳梨酥做法",
    "健身訓練",
    "自行車旅遊",
    "健康飲食",


    ; ===== 其他 =====

    "棒球新聞",
    "籃球新聞",
    "F1 賽車",
    "世界旅遊",
    "攝影技巧",
    "繪畫教學",
    "英文學習",
    "程式設計",
    "Python 教學",
    "日本美食"
]


; ============================================================
; 🖥 GUI
; ============================================================

global MyGui := Gui(
    "+AlwaysOnTop",
    "Search Runner"
)

MyGui.BackColor := "20242C"

MyGui.SetFont(
    "s11 cFFFFFF",
    "Segoe UI"
)


; ------------------------------------------------------------
; 標題
; ------------------------------------------------------------

MyGui.SetFont(
    "s12 Bold cFFFFFF"
)

MyGui.AddText(
    "xm ym",
    "🔎 Search Runner"
)

MyGui.SetFont(
    "s8 Norm cAAB2C0"
)

MyGui.AddText(
    "xm y+3",
    "Edge Search Automation"
)


; ------------------------------------------------------------
; 分隔
; ------------------------------------------------------------

MyGui.AddText(
    "xm y+12 w280 h1 Background404650"
)


; ------------------------------------------------------------
; 執行次數
; ------------------------------------------------------------

MyGui.SetFont(
    "s9 cFFFFFF"
)

MyGui.AddText(
    "xm y+15",
    "執行次數"
)

global CountEdit := MyGui.AddEdit(
    "x+15 yp-4 w70 h26 Number Center",
    DEFAULT_COUNT
)

; 輸入框為白色背景，使用深色文字避免搜尋次數看不見
CountEdit.SetFont("s9 c000000")

MyGui.AddText(
    "xm y+14",
    "詞庫來源"
)

global SourceModeDropDown := MyGui.AddDropDownList(
    "x+15 yp-4 w125 Choose1",
    ["混合", "線上熱門詞", "自訂 TXT"]
)

global OpenKeywordsBtn := MyGui.AddButton(
    "x+5 yp w95 h26",
    "打開 TXT"
)


; ------------------------------------------------------------
; Edge 狀態
; ------------------------------------------------------------

MyGui.AddText(
    "xm y+17",
    "目標瀏覽器"
)

global EdgeStatusText := MyGui.AddText(
    "x+12 yp w150",
    "● 等待偵測"
)


; ------------------------------------------------------------
; 狀態
; ------------------------------------------------------------

MyGui.AddText(
    "xm y+12",
    "狀態"
)

global StatusText := MyGui.AddText(
    "x+15 yp w190",
    "待命"
)


; ------------------------------------------------------------
; 進度
; ------------------------------------------------------------

MyGui.AddText(
    "xm y+15",
    "進度"
)

global ProgressLabel := MyGui.AddText(
    "x+15 yp w100",
    "0 / " DEFAULT_COUNT
)

global ProgressBar := MyGui.AddProgress(
    "xm y+7 w280 h12 Range0-100",
    0
)


; ------------------------------------------------------------
; 關鍵字
; ------------------------------------------------------------

MyGui.SetFont(
    "s8 cAAB2C0"
)

MyGui.AddText(
    "xm y+17 w280 Center",
    "目前關鍵字"
)

MyGui.SetFont(
    "s11 Bold cFFFFFF"
)

global KeywordText := MyGui.AddText(
    "xm y+5 w280 h28 Center",
    "--"
)


; ------------------------------------------------------------
; 倒數
; ------------------------------------------------------------

MyGui.SetFont(
    "s8 Norm cAAB2C0"
)

MyGui.AddText(
    "xm y+10 w280 Center",
    "下一次搜尋"
)

MyGui.SetFont(
    "s20 Bold cFFFFFF"
)

global CountdownText := MyGui.AddText(
    "xm y+3 w280 h38 Center",
    "--"
)


; ------------------------------------------------------------
; Buttons
; ------------------------------------------------------------

MyGui.SetFont(
    "s9 Norm c000000"
)

global StartBtn := MyGui.AddButton(
    "xm y+14 w86 h32",
    "▶ 開始"
)

global PauseBtn := MyGui.AddButton(
    "x+11 yp w86 h32",
    "⏸ 暫停"
)

global StopBtn := MyGui.AddButton(
    "x+11 yp w86 h32",
    "■ 停止"
)


; ------------------------------------------------------------
; Footer
; ------------------------------------------------------------

MyGui.SetFont(
    "s8 c8D96A5"
)

MyGui.AddText(
    "xm y+13 w280 Center",
    "8.5～10.0 秒隨機間隔"
)

MyGui.AddText(
    "xm y+4 w280 Center",
    "F8 開始　F9 暫停　F10 停止"
)


; ============================================================
; 🖱 GUI Events
; ============================================================

StartBtn.OnEvent(
    "Click",
    StartRunner
)

PauseBtn.OnEvent(
    "Click",
    TogglePause
)

StopBtn.OnEvent(
    "Click",
    StopRunner
)

OpenKeywordsBtn.OnEvent(
    "Click",
    OpenKeywordsFile
)

MyGui.OnEvent(
    "Close",
    (*) => ExitApp()
)


; ============================================================
; 顯示 GUI
; ============================================================

MyGui.Show(
    "w310 AutoSize"
)


; ============================================================
; 🔍 Edge 狀態偵測
; ============================================================

SetTimer(
    CheckEdgeStatus,
    1000
)


CheckEdgeStatus() {

    global EDGE_EXE
    global EdgeStatusText

    if WinExist(EDGE_EXE) {

        EdgeStatusText.Text := "● Edge 已開啟"

    } else {

        EdgeStatusText.Text := "● 找不到 Edge"
    }
}


; ============================================================
; ▶ 開始
; ============================================================

StartRunner(*) {

    global Running
    global Paused

    global Current
    global Total

    global KeywordQueue
    global RemainingMs

    global CountEdit
    global SourceMode
    global SourceModeDropDown

    global StatusText
    global KeywordText
    global CountdownText

    global PauseBtn

    global EDGE_EXE


    ; --------------------------------------------------------
    ; 防止重複按開始
    ; --------------------------------------------------------

    if Running
        return


    ; --------------------------------------------------------
    ; 先確認 Edge 是否存在
    ; --------------------------------------------------------

    if !WinExist(EDGE_EXE) {

        StatusText.Text := "找不到 Microsoft Edge"

        CountdownText.Text := "NO EDGE"

        MsgBox(
            "目前沒有偵測到 Microsoft Edge。`n`n請先開啟 Edge，再按「開始」。",
            "Search Runner",
            "Icon!"
        )

        return
    }


    ; --------------------------------------------------------
    ; 讀取搜尋次數
    ; --------------------------------------------------------

    try {

        Total := Integer(CountEdit.Value)

    } catch {

        Total := DEFAULT_COUNT
    }


    if (Total < 1)
        Total := DEFAULT_COUNT


    ; 最大限制
    if (Total > 999)
        Total := 999


    CountEdit.Value := Total


    ; --------------------------------------------------------
    ; 建立隨機搜尋佇列
    ; --------------------------------------------------------

    StatusText.Text := "更新詞庫中..."
    SourceMode := SourceModeDropDown.Text
    RefreshKeywordPool()

    KeywordQueue := CreateKeywordQueue(Total)


    ; --------------------------------------------------------
    ; 初始化
    ; --------------------------------------------------------

    Current := 0

    RemainingMs := 0

    Running := true

    Paused := false


    PauseBtn.Text := "⏸ 暫停"


    StatusText.Text := "準備搜尋"


    KeywordText.Text := "--"


    CountdownText.Text := "GO"


    UpdateProgress()


    ; --------------------------------------------------------
    ; 立即執行第一筆
    ; --------------------------------------------------------

    SetTimer(
        RunnerTick,
        -150
    )
}


; ============================================================
; 🚀 主 Runner
; ============================================================

RunnerTick() {

    global Running
    global Paused

    global Current
    global Total

    global KeywordQueue
    global CurrentKeyword

    global StatusText
    global KeywordText
    global CountdownText

    global EDGE_EXE

    global MIN_DELAY
    global MAX_DELAY


    ; --------------------------------------------------------
    ; 是否仍在執行
    ; --------------------------------------------------------

    if !Running
        return


    if Paused
        return


    ; --------------------------------------------------------
    ; 是否已完成
    ; --------------------------------------------------------

    if (Current >= Total) {

        FinishRunner()

        return
    }


    ; ========================================================
    ; 🎯 每一次搜尋都重新確認 Edge
    ; ========================================================

    if !WinExist(EDGE_EXE) {

        RunnerError("Edge 已關閉")

        return
    }


    ; --------------------------------------------------------
    ; ⭐ 主動將 Edge 拉到最前面
    ; --------------------------------------------------------

    try {

        WinActivate(EDGE_EXE)

    } catch {

        RunnerError("無法啟用 Edge")

        return
    }


    ; --------------------------------------------------------
    ; ⭐ 等待 Edge 真正取得焦點
    ; 最多等待 2 秒
    ; --------------------------------------------------------

    if !WinWaitActive(
        EDGE_EXE,
        ,
        2
    ) {

        RunnerError("Edge 無法取得焦點")

        return
    }


    ; --------------------------------------------------------
    ; Edge 已經確定在前景
    ; 再取得下一個關鍵字
    ; --------------------------------------------------------

    Current += 1


    CurrentKeyword := KeywordQueue[Current]


    StatusText.Text := "搜尋第 " Current " 次"


    KeywordText.Text := CurrentKeyword


    CountdownText.Text := "搜尋中"


    UpdateProgress()


    ; ========================================================
    ; 🔎 真正的搜尋流程
    ;
    ; 1. Ctrl + L
    ; 2. 等待網址列取得焦點
    ; 3. 輸入「純關鍵字」
    ; 4. Enter
    ;
    ; 沒有組合任何搜尋網址
    ; ========================================================

    Send("^l")


    ; 給 Edge 一點時間
    ; 讓網址列確實取得焦點
    Sleep(250)


    ; --------------------------------------------------------
    ; 只輸入純關鍵字
    ; --------------------------------------------------------

    SendText(CurrentKeyword)


    Sleep(180)


    ; --------------------------------------------------------
    ; Enter
    ; --------------------------------------------------------

    Send("{Enter}")


    ; --------------------------------------------------------
    ; 最後一次
    ; --------------------------------------------------------

    if (Current >= Total) {

        SetTimer(
            FinishRunner,
            -700
        )

        return
    }


    ; --------------------------------------------------------
    ; 下一次等待 8.5～10 秒
    ; --------------------------------------------------------

    Delay := Random(MIN_DELAY, MAX_DELAY)


    StartCountdown(Delay)
}


; ============================================================
; ⏱ 開始倒數
; ============================================================

StartCountdown(ms) {

    global RemainingMs
    global StatusText


    RemainingMs := ms


    StatusText.Text := "等待下一次搜尋"


    SetTimer(
        CountdownTick,
        100
    )
}


; ============================================================
; ⏱ 倒數 Timer
; ============================================================

CountdownTick() {

    global Running
    global Paused

    global RemainingMs

    global CountdownText


    ; --------------------------------------------------------
    ; 已停止
    ; --------------------------------------------------------

    if !Running {

        SetTimer(
            CountdownTick,
            0
        )

        return
    }


    ; --------------------------------------------------------
    ; 暫停時完全不扣時間
    ; --------------------------------------------------------

    if Paused
        return


    ; --------------------------------------------------------
    ; 每 100ms 扣除
    ; --------------------------------------------------------

    RemainingMs -= 100


    ; --------------------------------------------------------
    ; 時間到
    ; --------------------------------------------------------

    if (RemainingMs <= 0) {

        RemainingMs := 0


        CountdownText.Text := "0.0 s"


        SetTimer(
            CountdownTick,
            0
        )


        ; 下一次搜尋
        SetTimer(
            RunnerTick,
            -20
        )


        return
    }


    ; --------------------------------------------------------
    ; 顯示一位小數
    ; --------------------------------------------------------

    CountdownText.Text := Format("{:.1f} s", RemainingMs / 1000)
}


; ============================================================
; ⏸ 暫停 / 繼續
; ============================================================

TogglePause(*) {

    global Running
    global Paused

    global RemainingMs

    global StatusText
    global PauseBtn
    global CountdownText


    ; 沒有執行時忽略
    if !Running
        return


    Paused := !Paused


    ; --------------------------------------------------------
    ; 暫停
    ; --------------------------------------------------------

    if Paused {

        StatusText.Text := "已暫停"


        PauseBtn.Text := "▶ 繼續"


        CountdownText.Text := "PAUSE"

        return
    }


    ; --------------------------------------------------------
    ; 繼續
    ; --------------------------------------------------------

    StatusText.Text := "等待下一次搜尋"


    PauseBtn.Text := "⏸ 暫停"


    ; 恢復原本剩餘時間
    if (RemainingMs > 0) {

        CountdownText.Text := Format("{:.1f} s", RemainingMs / 1000)

        SetTimer(
            CountdownTick,
            100
        )

    } else {

        CountdownText.Text := "GO"

        SetTimer(
            RunnerTick,
            -100
        )
    }
}


; ============================================================
; ■ 停止
; ============================================================

StopRunner(*) {

    global Running
    global Paused

    global Current
    global RemainingMs

    global StatusText
    global KeywordText
    global CountdownText

    global PauseBtn


    Running := false

    Paused := false

    Current := 0

    RemainingMs := 0


    ; 停止倒數
    SetTimer(
        CountdownTick,
        0
    )


    StatusText.Text := "已停止"


    KeywordText.Text := "--"


    CountdownText.Text := "--"


    PauseBtn.Text := "⏸ 暫停"


    UpdateProgress()
}


; ============================================================
; ❌ 執行錯誤
; ============================================================

RunnerError(message) {

    global Running
    global Paused

    global RemainingMs

    global StatusText
    global CountdownText
    global PauseBtn


    Running := false

    Paused := false

    RemainingMs := 0


    SetTimer(
        CountdownTick,
        0
    )


    StatusText.Text := message


    CountdownText.Text := "ERROR"


    PauseBtn.Text := "⏸ 暫停"


    SoundBeep(
        600,
        250
    )
}


; ============================================================
; ✓ 全部完成
; ============================================================

FinishRunner() {

    global Running
    global Paused

    global RemainingMs

    global StatusText
    global CountdownText
    global PauseBtn


    ; 避免重複 Finish
    if !Running
        return


    Running := false

    Paused := false

    RemainingMs := 0


    SetTimer(
        CountdownTick,
        0
    )


    StatusText.Text := "全部完成 ✓"


    CountdownText.Text := "完成 ✓"


    PauseBtn.Text := "⏸ 暫停"


    UpdateProgress()


    ; --------------------------------------------------------
    ; 完成提示音
    ; --------------------------------------------------------

    SoundBeep(
        1000,
        160
    )

    Sleep(80)

    SoundBeep(
        1300,
        180
    )
}


; ============================================================
; 📊 更新進度
; ============================================================

UpdateProgress() {

    global Current
    global Total

    global ProgressLabel
    global ProgressBar


    if (Total <= 0) {

        Percent := 0

    } else {

        Percent := Round(Current / Total * 100)
    }


    ProgressLabel.Text := Current " / " Total


    ProgressBar.Value := Percent
}


; ============================================================
; 🌐 更新混合詞庫
; ============================================================

OpenKeywordsFile(*) {

    global CUSTOM_KEYWORDS_FILE

    if !FileExist(CUSTOM_KEYWORDS_FILE) {
        FileAppend(
            "; 使用者自訂關鍵字：每行一個`n; 例如：`n; 桃園咖啡廳`n; 八德美食`n",
            CUSTOM_KEYWORDS_FILE,
            "UTF-8"
        )
    }

    Run(CUSTOM_KEYWORDS_FILE)
}

RefreshKeywordPool() {

    global Keywords
    global CUSTOM_KEYWORDS_FILE
    global ONLINE_KEYWORD_FEEDS
    global SourceMode

    OriginalKeywords := Keywords.Clone()
    NewKeywords := []
    Seen := Map()

    ; 混合或純線上模式：抓取內建線上來源
    if (SourceMode != "自訂 TXT") {
        for FeedUrl in ONLINE_KEYWORD_FEEDS {
            try {
                Http := ComObject("WinHttp.WinHttpRequest.5.1")
                Http.Open("GET", FeedUrl, false)
                Http.SetRequestHeader("User-Agent", "Mozilla/5.0")
                Http.Send()

                if (Http.Status = 200)
                    AddRssTitles(Http.ResponseText, NewKeywords, Seen)
            }
        }
    }

    ; 混合或自訂模式：讀取使用者自訂詞，每行一個
    if (SourceMode != "線上熱門詞") {
        if !FileExist(CUSTOM_KEYWORDS_FILE) {
            FileAppend(
                "; 使用者自訂關鍵字：每行一個`n; 例如：`n; 桃園咖啡廳`n; 八德美食`n",
                CUSTOM_KEYWORDS_FILE,
                "UTF-8"
            )
        }

        try {
            CustomText := FileRead(CUSTOM_KEYWORDS_FILE, "UTF-8")
            for Line in StrSplit(CustomText, "`n", "`r") {
                AddKeyword(Line, NewKeywords, Seen)
            }
        }
    }

    ; 混合模式保留原本內建詞；其他模式只有完全沒有取得內容時才備援
    if (SourceMode = "混合" || NewKeywords.Length = 0) {
        for Keyword in OriginalKeywords
            AddKeyword(Keyword, NewKeywords, Seen)
    }

    if (NewKeywords.Length > 0)
        Keywords := NewKeywords
}


AddRssTitles(XmlText, Result, Seen) {

    Position := 1

    while Position := RegExMatch(XmlText, "<title[^>]*>(.*?)</title>", &Match, Position) {
        AddKeyword(Match[1], Result, Seen, 10)
        Position += Match.Len
    }
}


AddKeyword(Value, Result, Seen, MaxLength := 0) {

    Value := Trim(Value)

    if (SubStr(Value, 1, 1) = ";" || SubStr(Value, 1, 1) = "#")
        return

    ; 清除 RSS 常見的 CDATA 與 HTML 標記
    Value := RegExReplace(Value, "<!\[CDATA\[(.*?)\]\]>", "$1")
    Value := RegExReplace(Value, "<[^>]+>", "")
    Value := RegExReplace(Value, "[\r\n\t]+", " ")
    Value := Trim(Value)

    Value := StrReplace(Value, "&amp;", "&")
    Value := StrReplace(Value, "&quot;", '"')
    Value := StrReplace(Value, "&#39;", "'")
    Value := StrReplace(Value, "&lt;", "<")
    Value := StrReplace(Value, "&gt;", ">")

    if (Value = "")
        return

    ; 排除 RSS 標題與過長內容，避免把整段新聞摘要當成關鍵字
    if (Value = "Google Trends" || Value = "新聞")
        return

    ; 線上新聞標題只保留前 10 個字；自訂詞與內建詞不截短
    if (MaxLength > 0 && StrLen(Value) > MaxLength)
        Value := SubStr(Value, 1, MaxLength)

    Key := StrLower(Value)
    if Seen.Has(Key)
        return

    Seen[Key] := true
    Result.Push(Value)
}


; ============================================================
; 🎲 建立關鍵字 Queue
; ============================================================

CreateKeywordQueue(total) {

    global Keywords


    Result := []


    ; --------------------------------------------------------
    ; 如果搜尋次數超過 100
    ;
    ; 第一輪 100 個不重複
    ; 第二輪再重新洗牌
    ; --------------------------------------------------------

    while (
        Result.Length < total
    ) {

        Pool := []


        ; ----------------------------------------------------
        ; 複製原始關鍵字
        ; ----------------------------------------------------

        for Keyword in Keywords {

            Pool.Push(
                Keyword
            )
        }


        ; ----------------------------------------------------
        ; Fisher-Yates Shuffle
        ; ----------------------------------------------------

        if (
            Pool.Length > 1
        ) {

            Loop (
                Pool.Length - 1
            ) {

                i := Pool.Length - A_Index + 1


                j := Random(1, i)


                Temp := Pool[i]


                Pool[i] := Pool[j]


                Pool[j] := Temp
            }
        }


        ; ----------------------------------------------------
        ; 加入結果
        ; ----------------------------------------------------

        for Keyword in Pool {

            Result.Push(
                Keyword
            )


            if (
                Result.Length >= total
            )
                break
        }
    }


    return Result
}


; ============================================================
; ⌨️ 快捷鍵
; ============================================================

F8::{
    StartRunner()
}


F9::{
    TogglePause()
}


F10::{
    StopRunner()
}
