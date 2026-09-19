using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Xml.Linq;

namespace BingRunner;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}

internal sealed class MainForm : Form
{
    private readonly struct BrowserTarget
    {
        internal BrowserTarget(IntPtr handle, string name) { Handle = handle; Name = name; }
        internal IntPtr Handle { get; }
        internal string Name { get; }
    }

    private const int DefaultCount = 22;
    private const int MinDelayMs = 8500;
    private const int MaxDelayMs = 10000;
    private const float UiScale = 0.72F;

    private readonly NumericUpDown countBox = new();
    private readonly ComboBox sourceBox = new();
    private readonly ComboBox browserBox = new();
    private readonly Label browserStatus = new();
    private readonly Label status = new();
    private readonly Label progressLabel = new();
    private readonly ProgressBar progress = new();
    private readonly Label keywordLabel = new();
    private readonly Label countdownLabel = new();
    private Button startButton = new();
    private Button pauseButton = new();
    private Button stopButton = new();
    private readonly System.Windows.Forms.Timer browserTimer = new() { Interval = 1000 };
    private readonly HttpClient http = new() { Timeout = TimeSpan.FromSeconds(8) };

    private CancellationTokenSource? runCts;
    private volatile bool paused;
    private int current;
    private int total = DefaultCount;
    private readonly string customFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "keywords.txt");
    private static readonly Random Rng = new Random();

    private static readonly string[] Feeds =
    new[]
    {
        "https://trends.google.com/trending/rss?geo=TW",
        "https://news.google.com/rss?hl=zh-TW&gl=TW&ceid=TW:zh-Hant",
        "https://tw.news.yahoo.com/rss"
    };

    private static readonly string[] BuiltInKeywords =
    new[]
    {
        "台灣天氣", "今日新聞", "台灣新聞", "桃園天氣", "台北天氣", "高雄天氣", "台中天氣", "颱風最新消息", "地震最新消息", "中央氣象署",
        "桃園景點", "台北景點", "新北景點", "台中景點", "台南景點", "高雄景點", "宜蘭景點", "花蓮景點", "台東景點", "澎湖景點",
        "桃園美食", "台北美食", "台中美食", "台南美食", "高雄美食", "基隆美食", "新竹美食", "嘉義美食", "宜蘭美食", "花蓮美食",
        "台灣高鐵", "台鐵時刻表", "高速公路路況", "桃園機場", "台北捷運", "桃園捷運", "台中捷運", "高雄捷運", "台灣公車", "國道即時路況",
        "日本旅遊", "東京旅遊", "大阪旅遊", "京都旅遊", "北海道旅遊", "沖繩旅遊", "福岡旅遊", "廣島旅遊", "東京景點", "大阪景點",
        "韓國旅遊", "首爾旅遊", "釜山旅遊", "泰國旅遊", "曼谷旅遊", "新加坡旅遊", "馬來西亞旅遊", "越南旅遊", "香港旅遊", "澳門旅遊",
        "人工智慧", "科技新聞", "手機推薦", "筆電推薦", "電腦組裝", "Windows 11", "Android 手機", "iPhone 最新消息", "AI 最新消息", "電動車最新消息",
        "台灣股市", "台股今日行情", "美國股市", "美元匯率", "日幣匯率", "黃金價格", "國際油價", "房價趨勢", "ETF 投資", "財經新聞",
        "電影推薦", "Netflix 推薦", "動畫推薦", "咖啡推薦", "甜點推薦", "蛋黃酥做法", "鳳梨酥做法", "健身訓練", "自行車旅遊", "健康飲食",
        "棒球新聞", "籃球新聞", "F1 賽車", "世界旅遊", "攝影技巧", "繪畫教學", "英文學習", "程式設計", "Python 教學", "日本美食"
    };

    public MainForm()
    {
        Text = "Search Runner";
        AutoScaleMode = AutoScaleMode.None;
        ClientSize = new Size(Px(450), Px(670));
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        TopMost = true;
        BackColor = Color.FromArgb(31, 36, 44);
        ForeColor = Color.White;
        Font = new Font("Segoe UI", 10F);
        StartPosition = FormStartPosition.CenterScreen;

        BuildUi();
        EnsureCustomFile();
        browserTimer.Tick += (_, _) => UpdateBrowserStatus();
        browserTimer.Start();
        UpdateBrowserStatus();
        FormClosing += (_, _) => runCts?.Cancel();
    }

    private void BuildUi()
    {
        Controls.Add(MakeLabel("🔎 Search Runner", 20, 15, 400, 34, 16F, true));
        Controls.Add(MakeLabel("Browser Search Automation", 20, 50, 400, 25, 9F, false, Color.LightSteelBlue));
        Controls.Add(new Panel { Left = Px(20), Top = Px(87), Width = Px(410), Height = 1, BackColor = Color.FromArgb(65, 72, 83) });

        Controls.Add(MakeLabel("執行次數", 20, 110, 90, 30));
        countBox.SetBounds(Px(120), Px(106), Px(105), Px(34));
        countBox.Minimum = 1; countBox.Maximum = 999; countBox.Value = DefaultCount;
        countBox.TextAlign = HorizontalAlignment.Center;
        countBox.BackColor = Color.White; countBox.ForeColor = Color.Black;
        Controls.Add(countBox);

        Controls.Add(MakeLabel("詞庫來源", 20, 157, 90, 30));
        sourceBox.SetBounds(Px(120), Px(153), Px(200), Px(34));
        sourceBox.DropDownStyle = ComboBoxStyle.DropDownList;
        sourceBox.Items.AddRange(new object[] { "混合", "線上熱門詞", "自訂 TXT" });
        sourceBox.SelectedIndex = 0;
        Controls.Add(sourceBox);
        var openButton = MakeButton("打開 TXT", 330, 153, 100, 34);
        openButton.Click += (_, _) => OpenCustomFile();
        Controls.Add(openButton);

        Controls.Add(MakeLabel("目標瀏覽器", 20, 210, 100, 30));
        browserBox.SetBounds(Px(120), Px(206), Px(145), Px(34));
        browserBox.DropDownStyle = ComboBoxStyle.DropDownList;
        browserBox.Items.AddRange(new object[] { "自動偵測", "Microsoft Edge", "Google Chrome" });
        browserBox.SelectedIndex = 0;
        browserBox.SelectedIndexChanged += (_, _) => UpdateBrowserStatus();
        Controls.Add(browserBox);
        browserStatus.SetBounds(Px(275), Px(210), Px(155), Px(30)); browserStatus.ForeColor = Color.White;
        Controls.Add(browserStatus);
        Controls.Add(MakeLabel("狀態", 20, 250, 60, 30));
        status.SetBounds(Px(85), Px(250), Px(330), Px(30)); status.Text = "待命";
        Controls.Add(status);

        Controls.Add(MakeLabel("進度", 20, 300, 60, 30));
        progressLabel.SetBounds(Px(85), Px(300), Px(120), Px(30)); progressLabel.Text = $"0 / {DefaultCount}";
        Controls.Add(progressLabel);
        progress.SetBounds(Px(20), Px(335), Px(410), Px(18)); progress.Maximum = 100;
        Controls.Add(progress);

        Controls.Add(MakeLabel("目前關鍵字", 20, 385, 410, 25, 9F, false, Color.LightSteelBlue, ContentAlignment.MiddleCenter));
        keywordLabel.SetBounds(Px(20), Px(415), Px(410), Px(40)); keywordLabel.Text = "--"; keywordLabel.Font = new Font("Segoe UI", 12.5F, FontStyle.Bold); keywordLabel.TextAlign = ContentAlignment.MiddleCenter;
        Controls.Add(keywordLabel);
        Controls.Add(MakeLabel("下一次搜尋", 20, 475, 410, 25, 9F, false, Color.LightSteelBlue, ContentAlignment.MiddleCenter));
        countdownLabel.SetBounds(Px(20), Px(505), Px(410), Px(55)); countdownLabel.Text = "--"; countdownLabel.Font = new Font("Segoe UI", 18F, FontStyle.Bold); countdownLabel.TextAlign = ContentAlignment.MiddleCenter;
        Controls.Add(countdownLabel);

        startButton = MakeButton("▶ 開始", 20, 580, 125, 42);
        pauseButton = MakeButton("⏸ 暫停", 162, 580, 125, 42);
        stopButton = MakeButton("■ 停止", 304, 580, 125, 42);
        startButton.Click += async (_, _) => await StartRunnerAsync();
        pauseButton.Click += (_, _) => TogglePause();
        stopButton.Click += (_, _) => StopRunner();
        Controls.AddRange(new Control[] { startButton, pauseButton, stopButton });
        Controls.Add(MakeLabel("F8 開始　│　F9 暫停　│　F10 停止", 20, 635, 410, 25, 9.8F, false, Color.FromArgb(170, 180, 195), ContentAlignment.MiddleCenter));
    }

    private static int Px(int value) => Math.Max(1, (int)Math.Round(value * UiScale));

    private static Label MakeLabel(string text, int x, int y, int w, int h, float size = 10F, bool bold = false, Color? color = null, ContentAlignment align = ContentAlignment.MiddleLeft) =>
        new() { Text = text, Left = Px(x), Top = Px(y), Width = Px(w), Height = Px(h), Font = new Font("Segoe UI", size * 0.9F, bold ? FontStyle.Bold : FontStyle.Regular), ForeColor = color ?? Color.White, TextAlign = align };

    private static Button MakeButton(string text, int x, int y, int w, int h) =>
        new() { Text = text, Left = Px(x), Top = Px(y), Width = Px(w), Height = Px(h), BackColor = Color.White, ForeColor = Color.Black, FlatStyle = FlatStyle.Standard };

    protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
    {
        if (keyData == Keys.F8) { _ = StartRunnerAsync(); return true; }
        if (keyData == Keys.F9) { TogglePause(); return true; }
        if (keyData == Keys.F10) { StopRunner(); return true; }
        return base.ProcessCmdKey(ref msg, keyData);
    }

    private async Task StartRunnerAsync()
    {
        if (runCts is not null) return;
        var initialBrowser = GetBrowserTarget();
        if (initialBrowser.Handle == IntPtr.Zero)
        {
            status.Text = "找不到目標瀏覽器";
            countdownLabel.Text = "NO BROWSER";
            MessageBox.Show($"請先開啟{GetRequestedBrowserText()}。", "Search Runner", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        total = (int)countBox.Value;
        current = 0; paused = false; pauseButton.Text = "⏸ 暫停";
        runCts = new CancellationTokenSource();
        SetControlsRunning(true);
        status.Text = "更新詞庫中..."; countdownLabel.Text = "GO"; keywordLabel.Text = "--"; UpdateProgress();

        try
        {
            var pool = await BuildKeywordPoolAsync(sourceBox.Text, runCts.Token);
            var queue = CreateQueue(pool, total);
            for (var i = 0; i < queue.Count; i++)
            {
                runCts.Token.ThrowIfCancellationRequested();
                while (paused) await Task.Delay(100, runCts.Token);

                var browser = GetBrowserTarget();
                if (browser.Handle == IntPtr.Zero) throw new InvalidOperationException($"{GetRequestedBrowserText()} 已關閉");
                Native.ActivateWindow(browser.Handle);
                await WaitForForegroundAsync(browser.Handle, browser.Name, runCts.Token);
                await Task.Delay(150, runCts.Token);

                current = i + 1;
                keywordLabel.Text = queue[i]; status.Text = $"搜尋第 {current} 次"; countdownLabel.Text = "搜尋中"; UpdateProgress();
                Native.PressCtrlL(); await Task.Delay(180, runCts.Token);
                Native.TypeUnicode(queue[i]); await Task.Delay(120, runCts.Token);
                Native.PressEnter();

                if (current < total)
                    await CountdownAsync(NextRandom(MinDelayMs, MaxDelayMs + 1), runCts.Token);
            }

            status.Text = "全部完成 ✓"; countdownLabel.Text = "完成 ✓";
            System.Media.SystemSounds.Asterisk.Play();
        }
        catch (OperationCanceledException) { }
        catch (Exception ex) { status.Text = ex.Message; countdownLabel.Text = "ERROR"; System.Media.SystemSounds.Hand.Play(); }
        finally { runCts?.Dispose(); runCts = null; paused = false; pauseButton.Text = "⏸ 暫停"; SetControlsRunning(false); }
    }

    private async Task CountdownAsync(int milliseconds, CancellationToken token)
    {
        var remaining = milliseconds;
        status.Text = "等待下一次搜尋";
        while (remaining > 0)
        {
            token.ThrowIfCancellationRequested();
            if (!paused) { countdownLabel.Text = $"{remaining / 1000.0:0.0} s"; remaining -= 100; }
            else { countdownLabel.Text = "PAUSE"; }
            await Task.Delay(100, token);
        }
        countdownLabel.Text = "0.0 s";
    }

    private void TogglePause()
    {
        if (runCts is null) return;
        paused = !paused;
        pauseButton.Text = paused ? "▶ 繼續" : "⏸ 暫停";
        status.Text = paused ? "已暫停" : "等待下一次搜尋";
        if (paused) countdownLabel.Text = "PAUSE";
    }

    private void StopRunner()
    {
        if (runCts is null) return;
        runCts.Cancel(); status.Text = "已停止"; countdownLabel.Text = "--"; keywordLabel.Text = "--"; current = 0; UpdateProgress();
    }

    private void SetControlsRunning(bool running)
    {
        startButton.Enabled = !running; countBox.Enabled = !running; sourceBox.Enabled = !running; browserBox.Enabled = !running;
    }

    private void UpdateProgress()
    {
        progressLabel.Text = $"{current} / {total}";
        progress.Value = total > 0 ? Math.Max(0, Math.Min(100, (int)Math.Round(current * 100.0 / total))) : 0;
    }

    private void UpdateBrowserStatus()
    {
        var browser = GetBrowserTarget();
        browserStatus.Text = browser.Handle != IntPtr.Zero ? $"● {browser.Name} 已開啟" : "● 找不到";
    }

    private static async Task WaitForForegroundAsync(IntPtr browser, string browserName, CancellationToken token)
    {
        for (var attempt = 0; attempt < 20; attempt++)
        {
            if (Native.GetForegroundWindow() == browser) return;
            Native.ActivateWindow(browser);
            await Task.Delay(100, token);
        }
        throw new InvalidOperationException($"{browserName} 無法取得焦點");
    }

    private BrowserTarget GetBrowserTarget()
    {
        if (browserBox.SelectedIndex == 1) return new BrowserTarget(GetBrowserWindow("msedge"), "Edge");
        if (browserBox.SelectedIndex == 2) return new BrowserTarget(GetBrowserWindow("chrome"), "Chrome");

        var foreground = Native.GetForegroundWindow();
        var edge = GetBrowserWindow("msedge");
        var chrome = GetBrowserWindow("chrome");
        if (foreground != IntPtr.Zero && foreground == chrome) return new BrowserTarget(chrome, "Chrome");
        if (foreground != IntPtr.Zero && foreground == edge) return new BrowserTarget(edge, "Edge");
        if (edge != IntPtr.Zero) return new BrowserTarget(edge, "Edge");
        return new BrowserTarget(chrome, chrome != IntPtr.Zero ? "Chrome" : "瀏覽器");
    }

    private string GetRequestedBrowserText() => browserBox.SelectedIndex switch
    {
        1 => " Microsoft Edge",
        2 => " Google Chrome",
        _ => " Microsoft Edge 或 Google Chrome"
    };

    private static IntPtr GetBrowserWindow(string processName) =>
        Process.GetProcessesByName(processName).Select(p => p.MainWindowHandle).FirstOrDefault(h => h != IntPtr.Zero);

    private async Task<List<string>> BuildKeywordPoolAsync(string mode, CancellationToken token)
    {
        var result = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        if (mode != "自訂 TXT")
        {
            foreach (var url in Feeds)
            {
                try
                {
                    using var request = new HttpRequestMessage(HttpMethod.Get, url);
                    request.Headers.UserAgent.ParseAdd("Mozilla/5.0 BingRunner/2.0");
                    var xml = await http.SendAsync(request, token);
                    if (!xml.IsSuccessStatusCode) continue;
                    var document = XDocument.Parse(await xml.Content.ReadAsStringAsync());
                    foreach (var title in document.Descendants().Where(e => e.Name.LocalName == "title").Select(e => CleanOnlineTitle(e.Value)))
                        AddUnique(title, result, seen);
                }
                catch when (!token.IsCancellationRequested) { }
            }
        }

        if (mode != "線上熱門詞")
        {
            EnsureCustomFile();
            foreach (var line in await Task.Run(() => File.ReadAllLines(customFile), token))
                if (!line.TrimStart().StartsWith(";") && !line.TrimStart().StartsWith("#")) AddUnique(line, result, seen);
        }

        if (mode == "混合" || result.Count == 0)
            foreach (var item in BuiltInKeywords) AddUnique(item, result, seen);
        return result;
    }

    private static string CleanOnlineTitle(string value)
    {
        value = System.Net.WebUtility.HtmlDecode(value).Replace("<![CDATA[", "").Replace("]]>", "").Trim();
        return value.Length > 10 ? value.Substring(0, 10) : value;
    }

    private static void AddUnique(string value, List<string> result, HashSet<string> seen)
    {
        value = value.Trim();
        if (value.Length > 0 && seen.Add(value)) result.Add(value);
    }

    private static List<string> CreateQueue(List<string> source, int count)
    {
        var result = new List<string>(count);
        while (result.Count < count)
        {
            var round = source.OrderBy(_ => NextRandom()).ToList();
            result.AddRange(round.Take(count - result.Count));
        }
        return result;
    }

    private static int NextRandom(int min = 0, int max = int.MaxValue)
    {
        lock (Rng) return Rng.Next(min, max);
    }

    private void EnsureCustomFile()
    {
        if (!File.Exists(customFile)) File.WriteAllText(customFile, "; 使用者自訂關鍵字：每行一個\r\n; 桃園咖啡廳\r\n; 八德美食\r\n", new UTF8Encoding(true));
    }

    private void OpenCustomFile()
    {
        EnsureCustomFile();
        Process.Start(new ProcessStartInfo(customFile) { UseShellExecute = true });
    }
}

internal static class Native
{
    private const uint InputKeyboard = 1;
    private const uint KeyUp = 0x0002;
    private const uint Unicode = 0x0004;
    private const ushort VkControl = 0x11;
    private const ushort VkL = 0x4C;
    private const ushort VkEnter = 0x0D;

    private const int SwRestore = 9;

    [DllImport("user32.dll")] internal static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] internal static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] private static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] private static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);
    [DllImport("kernel32.dll")] private static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool attach);
    [DllImport("user32.dll", SetLastError = true)] private static extern uint SendInput(uint nInputs, INPUT[] inputs, int cbSize);

    internal static void ActivateWindow(IntPtr window)
    {
        if (IsIconic(window)) ShowWindowAsync(window, SwRestore);

        var foreground = GetForegroundWindow();
        var foregroundThread = foreground == IntPtr.Zero ? 0 : GetWindowThreadProcessId(foreground, IntPtr.Zero);
        var targetThread = GetWindowThreadProcessId(window, IntPtr.Zero);
        var currentThread = GetCurrentThreadId();

        try
        {
            if (foregroundThread != 0 && foregroundThread != currentThread)
                AttachThreadInput(currentThread, foregroundThread, true);
            if (targetThread != 0 && targetThread != currentThread)
                AttachThreadInput(currentThread, targetThread, true);

            BringWindowToTop(window);
            SetForegroundWindow(window);
        }
        finally
        {
            if (targetThread != 0 && targetThread != currentThread)
                AttachThreadInput(currentThread, targetThread, false);
            if (foregroundThread != 0 && foregroundThread != currentThread)
                AttachThreadInput(currentThread, foregroundThread, false);
        }
    }

    internal static void PressCtrlL() => SendKeys(new[] { Key(VkControl), Key(VkL), Key(VkL, KeyUp), Key(VkControl, KeyUp) });
    internal static void PressEnter() => SendKeys(new[] { Key(VkEnter), Key(VkEnter, KeyUp) });

    internal static void TypeUnicode(string text)
    {
        var inputs = new List<INPUT>();
        foreach (var ch in text) { inputs.Add(Key(ch, Unicode)); inputs.Add(Key(ch, Unicode | KeyUp)); }
        SendKeys(inputs.ToArray());
    }

    private static void SendKeys(INPUT[] inputs)
    {
        var sent = SendInput((uint)inputs.Length, inputs, Marshal.SizeOf<INPUT>());
        if (sent != inputs.Length) throw new Win32Exception(Marshal.GetLastWin32Error(), "無法傳送鍵盤輸入");
    }
    private static INPUT Key(ushort code, uint flags = 0) => new() { type = InputKeyboard, U = new INPUTUNION { ki = new KEYBDINPUT { wVk = (flags & Unicode) != 0 ? (ushort)0 : code, wScan = (flags & Unicode) != 0 ? code : (ushort)0, dwFlags = flags } } };

    [StructLayout(LayoutKind.Sequential)] private struct INPUT { public uint type; public INPUTUNION U; }
    [StructLayout(LayoutKind.Explicit, Size = 32)] private struct INPUTUNION { [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] private struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
}
