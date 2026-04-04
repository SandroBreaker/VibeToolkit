// ═══════════════════════════════════════════════════════════════════
//  VibeToolkit.HUD.Sentinel — SentinelHudViewModel.cs
//  Cyber-Noir Overlay HUD | MVVM · CommunityToolkit.Mvvm
//
//  NuGet dependencies:
//    · CommunityToolkit.Mvvm     ≥ 8.x
//    · Microsoft.Extensions.Logging (optional, for ILogger)
//
//  Namespace: VibeToolkit.HUD.Sentinel
// ═══════════════════════════════════════════════════════════════════

using System;
using System.Diagnostics;
using System.Linq;
using System.Net.NetworkInformation;
using System.Threading;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Effects;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace VibeToolkit.HUD.Sentinel
{
    // ─────────────────────────────────────────────────────────────────
    //  Enums & Constants
    // ─────────────────────────────────────────────────────────────────

    /// <summary>Operational status of the Sentinel HUD system.</summary>
    public enum SystemStatusLevel
    {
        Nominal,
        Alert,
        Critical
    }

    // ─────────────────────────────────────────────────────────────────
    //  ViewModel
    // ─────────────────────────────────────────────────────────────────

    /// <summary>
    /// ViewModel for SentinelHud.xaml.
    /// Implements the MVVM pattern via CommunityToolkit.Mvvm.
    /// Provides simulated + real system metrics, updated on a background
    /// timer at configurable Hz.
    /// </summary>
    public sealed partial class SentinelHudViewModel : ObservableObject, IDisposable
    {
        // ── Refresh configuration ────────────────────────────────────
        private const int RefreshIntervalMs   = 1_000; // 1 Hz UI refresh
        private const int ClockIntervalMs     = 500;   // 0.5 Hz clock (sub-second feel)
        private const double MaxBandwidthMbps = 1_000; // 1 Gbps reference for % bars

        // ── Timers ───────────────────────────────────────────────────
        private readonly Timer _metricsTimer;
        private readonly Timer _clockTimer;

        // ── Perf counters (real) ─────────────────────────────────────
        private readonly PerformanceCounter? _cpuCounter;
        private readonly PerformanceCounter? _ramCounter;

        // ── Random for GPU / net simulation ─────────────────────────
        private readonly Random _rng = new();
        private double _simCpuBase   = 25;
        private double _simRamBase   = 8.4;
        private double _simGpuBase   = 58;
        private double _simUpBase    = 12;
        private double _simDnBase    = 85;
        private double _simPingBase  = 18;

        // ── Session start for uptime ─────────────────────────────────
        private readonly DateTime _sessionStart = DateTime.Now;

        // ── Node identifier (one-time) ───────────────────────────────
        private readonly string _nodeId;

        // ════════════════════════════════════════════════════════════
        //  Constructor
        // ════════════════════════════════════════════════════════════

        public SentinelHudViewModel()
        {
            // Node ID from machine name, last 8 chars
            var raw  = Environment.MachineName.ToUpperInvariant();
            _nodeId  = raw.Length > 8 ? raw[^8..] : raw.PadRight(8, '0');

            // Attempt to create real CPU counter; fall back to simulation
            try
            {
                _cpuCounter = new PerformanceCounter(
                    "Processor", "% Processor Time", "_Total", readOnly: true);
                _cpuCounter.NextValue(); // first call always 0 — prime it
            }
            catch { _cpuCounter = null; }

            // Available RAM (MB)
            try
            {
                _ramCounter = new PerformanceCounter(
                    "Memory", "Available MBytes", readOnly: true);
            }
            catch { _ramCounter = null; }

            // Seed initial display values so UI isn't blank at startup
            RefreshMetrics();
            RefreshClock();

            // Start timers
            _metricsTimer = new Timer(_ => RefreshMetrics(), null,
                                      RefreshIntervalMs, RefreshIntervalMs);
            _clockTimer   = new Timer(_ => RefreshClock(),   null,
                                      ClockIntervalMs,   ClockIntervalMs);
        }

        // ════════════════════════════════════════════════════════════
        //  Observable Properties — GhostGirl Core
        // ════════════════════════════════════════════════════════════

        [ObservableProperty]
        private string _currentTime = "00:00:00";

        [ObservableProperty]
        private string _currentDate = "01/01/1970";

        /// <summary>Human-readable status: "NOMINAL" | "ALERT" | "CRITICAL".</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(StatusLevel))]
        private string _systemStatus = "NOMINAL";

        public SystemStatusLevel StatusLevel => SystemStatus switch
        {
            "ALERT"    => SystemStatusLevel.Alert,
            "CRITICAL" => SystemStatusLevel.Critical,
            _          => SystemStatusLevel.Nominal
        };

        // ════════════════════════════════════════════════════════════
        //  Observable Properties — System Module
        // ════════════════════════════════════════════════════════════

        /// <summary>CPU usage 0–100 (%).</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(CpuAlert))]
        private double _cpuUsage = 0;

        public bool CpuAlert => CpuUsage >= 80;

        /// <summary>RAM used in gigabytes.</summary>
        [ObservableProperty]
        private double _ramUsedGb = 0;

        /// <summary>RAM usage 0–100 (%) relative to TotalRamGb.</summary>
        [ObservableProperty]
        private double _ramUsagePercent = 0;

        /// <summary>GPU temperature in Celsius (simulated).</summary>
        [ObservableProperty]
        [NotifyPropertyChangedFor(nameof(GpuAlert))]
        private double _gpuTempCelsius = 0;

        public bool GpuAlert => GpuTempCelsius >= 85;

        [ObservableProperty]
        private int _cpuThreadCount = Environment.ProcessorCount;

        [ObservableProperty]
        private double _vramUsedGb = 0;

        // Total RAM — needed for percent calc
        private double TotalRamGb { get; } = GetTotalRamGb();

        private static double GetTotalRamGb()
        {
            try
            {
                using var searcher = new System.Management.ManagementObjectSearcher(
                    "SELECT Capacity FROM Win32_PhysicalMemory");
                ulong totalBytes = 0;
                foreach (var obj in searcher.Get())
                    totalBytes += (ulong)obj["Capacity"];
                return totalBytes / (1024.0 * 1024 * 1024);
            }
            catch { return 16.0; } // safe fallback
        }

        // ════════════════════════════════════════════════════════════
        //  Observable Properties — Network Module
        // ════════════════════════════════════════════════════════════

        [ObservableProperty]
        private string _uploadSpeedText = "0 Mbps";

        [ObservableProperty]
        private string _downloadSpeedText = "0 Mbps";

        /// <summary>Upload usage 0–100 % (relative to MaxBandwidthMbps).</summary>
        [ObservableProperty]
        private double _uploadPercent = 0;

        /// <summary>Download usage 0–100 %.</summary>
        [ObservableProperty]
        private double _downloadPercent = 0;

        /// <summary>Ping in milliseconds.</summary>
        [ObservableProperty]
        private int _pingMs = 0;

        // ════════════════════════════════════════════════════════════
        //  Observable Properties — Uptime Panel
        // ════════════════════════════════════════════════════════════

        [ObservableProperty]
        private string _uptimeText = "00:00:00";

        [ObservableProperty]
        private int _processCount = 0;

        /// <summary>Internal buffer for operational logs (plain text).</summary>
        [ObservableProperty]
        private string _logBuffer = string.Empty;

        public string NodeId => _nodeId;

        // ════════════════════════════════════════════════════════════
        //  Refresh Logic
        // ════════════════════════════════════════════════════════════

        /// <summary>
        /// Reads / simulates all metrics and dispatches property updates
        /// onto the UI thread via Application.Current.Dispatcher.
        /// </summary>
        private void RefreshMetrics()
        {
            // ── CPU ──────────────────────────────────────────────────
            double cpu;
            if (_cpuCounter != null)
            {
                try   { cpu = Math.Min(100, _cpuCounter.NextValue()); }
                catch { cpu = SimulateWalk(ref _simCpuBase, 5, 2, 95); }
            }
            else
            {
                cpu = SimulateWalk(ref _simCpuBase, 5, 2, 95);
            }

            // ── RAM ──────────────────────────────────────────────────
            double ramUsedGb;
            if (_ramCounter != null)
            {
                try
                {
                    double availMb  = _ramCounter.NextValue();
                    double totalMb  = TotalRamGb * 1024;
                    double usedMb   = totalMb - availMb;
                    ramUsedGb       = Math.Max(0, usedMb / 1024.0);
                }
                catch { ramUsedGb = SimulateWalk(ref _simRamBase, 0.3, 4, TotalRamGb * 0.95); }
            }
            else
            {
                ramUsedGb = SimulateWalk(ref _simRamBase, 0.3, 4, TotalRamGb * 0.95);
            }

            double ramPct = TotalRamGb > 0
                ? Math.Clamp(ramUsedGb / TotalRamGb * 100, 0, 100)
                : 0;

            // ── GPU (simulated) ──────────────────────────────────────
            double gpu = SimulateWalk(ref _simGpuBase, 3, 35, 95);

            // ── VRAM (simulated, ≤ 12 GB) ────────────────────────────
            double vram = Math.Round(_rng.NextDouble() * 1.5 + 3.0, 1);

            // ── Network (simulated) ──────────────────────────────────
            double up   = SimulateWalk(ref _simUpBase,   8, 0.1, MaxBandwidthMbps);
            double dn   = SimulateWalk(ref _simDnBase,  20, 0.1, MaxBandwidthMbps);
            double ping = SimulateWalk(ref _simPingBase, 6, 2, 300);

            // ── System status derivation ─────────────────────────────
            string status = DeriveStatus(cpu, gpu, (int)ping);

            // ── Process count ────────────────────────────────────────
            int procCount;
            try   { procCount = Process.GetProcesses().Length; }
            catch { procCount = _rng.Next(180, 280); }

            // ── Uptime ───────────────────────────────────────────────
            var uptime = DateTime.Now - _sessionStart;

            // ── Dispatch to UI thread ────────────────────────────────
            Application.Current?.Dispatcher.InvokeAsync(() =>
            {
                CpuUsage        = cpu;
                RamUsedGb       = ramUsedGb;
                RamUsagePercent = ramPct;
                GpuTempCelsius  = gpu;
                VramUsedGb      = vram;

                UploadSpeedText   = FormatSpeed(up);
                DownloadSpeedText = FormatSpeed(dn);
                UploadPercent     = Math.Clamp(up   / MaxBandwidthMbps * 100, 0, 100);
                DownloadPercent   = Math.Clamp(dn   / MaxBandwidthMbps * 100, 0, 100);
                PingMs            = (int)Math.Round(ping);

                SystemStatus  = status;
                ProcessCount  = procCount;
                UptimeText    = $"{(int)uptime.TotalHours:D2}:{uptime.Minutes:D2}:{uptime.Seconds:D2}";
            });
        }

        /// <summary>Updates the clock display.</summary>
        private void RefreshClock()
        {
            var now = DateTime.Now;
            Application.Current?.Dispatcher.InvokeAsync(() =>
            {
                CurrentTime = now.ToString("HH:mm:ss");
                CurrentDate = now.ToString("dd/MM/yyyy");
            });
        }

        // ════════════════════════════════════════════════════════════
        //  Helpers
        // ════════════════════════════════════════════════════════════

        /// <summary>
        /// Simulates a metric that walks randomly within [min, max]
        /// with a max delta per tick of <paramref name="step"/>.
        /// </summary>
        private double SimulateWalk(ref double current, double step,
                                    double min, double max)
        {
            double delta = (_rng.NextDouble() * 2 - 1) * step;
            current      = Math.Clamp(current + delta, min, max);
            return current;
        }

        private static string DeriveStatus(double cpu, double gpu, int ping)
        {
            if (cpu > 90 || gpu > 90 || ping > 200) return "CRITICAL";
            if (cpu > 70 || gpu > 75 || ping > 80)  return "ALERT";
            return "NOMINAL";
        }

        private static string FormatSpeed(double mbps)
        {
            if (mbps >= 1000) return $"{mbps / 1000:F1} Gbps";
            if (mbps >= 1)    return $"{mbps:F1} Mbps";
            return $"{mbps * 1000:F0} Kbps";
        }

        // ════════════════════════════════════════════════════════════
        //  Commands
        // ════════════════════════════════════════════════════════════

        /// <summary>Closes the HUD window.</summary>
        [RelayCommand]
        private void Close()
        {
            Application.Current?.Dispatcher.Invoke(() =>
            {
                foreach (Window w in Application.Current.Windows)
                {
                    if (w.DataContext == this)
                    {
                        w.Close();
                        return;
                    }
                }
                // fallback: close active window
                Application.Current.MainWindow?.Close();
            });
        }

        /// <summary>
        /// Initiates a window drag (DragMove).
        /// Call this from the code-behind on MouseLeftButtonDown of the drag handle.
        /// </summary>
        [RelayCommand]
        private void DragMove()
        {
            Application.Current?.Dispatcher.Invoke(() =>
            {
                foreach (Window w in Application.Current.Windows)
                {
                    if (w.DataContext == this)
                    {
                        if (w.WindowState == WindowState.Maximized)
                            w.WindowState = WindowState.Normal;
                        w.DragMove();
                        return;
                    }
                }
            });
        }

        /// <summary>Copies the current operational logs to the system clipboard.</summary>
        [RelayCommand]
        private void CopyLogs()
        {
            if (string.IsNullOrWhiteSpace(LogBuffer)) return;

            Application.Current?.Dispatcher.Invoke(() =>
            {
                try { Clipboard.SetText(LogBuffer); }
                catch (Exception ex) { Debug.WriteLine($"Clipboard failure: {ex.Message}"); }
            });
        }

        // ════════════════════════════════════════════════════════════
        //  IDisposable
        // ════════════════════════════════════════════════════════════

        private bool _disposed;

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            _metricsTimer.Dispose();
            _clockTimer.Dispose();
            _cpuCounter?.Dispose();
            _ramCounter?.Dispose();
        }
    }

    // ─────────────────────────────────────────────────────────────────
    //  Value Converters
    //  Place in the same file for portability, or split into
    //  SentinelConverters.cs.
    // ─────────────────────────────────────────────────────────────────

    /// <summary>
    /// Converts an integer ping value to a WPF SolidColorBrush.
    ///   ≤ 50 ms  → Green
    ///   ≤ 100 ms → Amber
    ///   > 100 ms → Coral Red
    /// </summary>
    public sealed class PingColorConverter : System.Windows.Data.IValueConverter
    {
        public static readonly PingColorConverter Instance = new();

        public object Convert(object value, Type targetType,
                              object parameter, System.Globalization.CultureInfo culture)
        {
            int ping = value is int p ? p : 0;

            var color = ping <= 50  ? Color.FromRgb(0x4B, 0xD7, 0xA5) :
                        ping <= 100 ? Color.FromRgb(0xFF, 0xC8, 0x57) :
                                      Color.FromRgb(0xFF, 0x6B, 0x6B);

            return new SolidColorBrush(color);
        }

        public object ConvertBack(object value, Type targetType,
                                  object parameter, System.Globalization.CultureInfo culture)
            => throw new NotSupportedException();
    }

    /// <summary>
    /// Converts an integer ping value to a DropShadowEffect (glow color matches ping severity).
    /// Glow reduced so nominal state stops screaming for attention like a cheap RGB cabinet.
    /// </summary>
    public sealed class PingGlowConverter : System.Windows.Data.IValueConverter
    {
        public static readonly PingGlowConverter Instance = new();

        public object Convert(object value, Type targetType,
                              object parameter, System.Globalization.CultureInfo culture)
        {
            int ping = value is int p ? p : 0;

            var color = ping <= 50  ? Color.FromRgb(0x4B, 0xD7, 0xA5) :
                        ping <= 100 ? Color.FromRgb(0xFF, 0xC8, 0x57) :
                                      Color.FromRgb(0xFF, 0x6B, 0x6B);

            double opacity = ping <= 50 ? 0.32 :
                             ping <= 100 ? 0.46 :
                                           0.60;

            double blur = ping <= 50 ? 8 :
                          ping <= 100 ? 10 :
                                        12;

            return new DropShadowEffect
            {
                Color        = color,
                BlurRadius   = blur,
                ShadowDepth  = 0,
                Opacity      = opacity
            };
        }

        public object ConvertBack(object value, Type targetType,
                                  object parameter, System.Globalization.CultureInfo culture)
            => throw new NotSupportedException();
    }

    /// <summary>
    /// Converts a SystemStatus string to a SolidColorBrush.
    ///   "NOMINAL"  → Cool Blue
    ///   "ALERT"    → Amber
    ///   "CRITICAL" → Coral Red
    /// </summary>
    public sealed class StatusColorConverter : System.Windows.Data.IValueConverter
    {
        public static readonly StatusColorConverter Instance = new();

        public object Convert(object value, Type targetType,
                              object parameter, System.Globalization.CultureInfo culture)
        {
            return (value as string) switch
            {
                "ALERT"    => new SolidColorBrush(Color.FromRgb(0xFF, 0xC8, 0x57)),
                "CRITICAL" => new SolidColorBrush(Color.FromRgb(0xFF, 0x6B, 0x6B)),
                _          => new SolidColorBrush(Color.FromRgb(0x7C, 0xC4, 0xFF))
            };
        }

        public object ConvertBack(object value, Type targetType,
                                  object parameter, System.Globalization.CultureInfo culture)
            => throw new NotSupportedException();
    }

    /// <summary>
    /// Converts a SystemStatus string to a DropShadowEffect glow.
    /// More restrained baseline, stronger only when the system is actually noisy.
    /// </summary>
    public sealed class StatusGlowConverter : System.Windows.Data.IValueConverter
    {
        public static readonly StatusGlowConverter Instance = new();

        public object Convert(object value, Type targetType,
                              object parameter, System.Globalization.CultureInfo culture)
        {
            var color = (value as string) switch
            {
                "ALERT"    => Color.FromRgb(0xFF, 0xC8, 0x57),
                "CRITICAL" => Color.FromRgb(0xFF, 0x6B, 0x6B),
                _          => Color.FromRgb(0x7C, 0xC4, 0xFF)
            };

            double opacity = (value as string) switch
            {
                "ALERT"    => 0.46,
                "CRITICAL" => 0.62,
                _          => 0.30
            };

            double blur = (value as string) switch
            {
                "ALERT"    => 11.0,
                "CRITICAL" => 14.0,
                _          => 8.0
            };

            return new DropShadowEffect
            {
                Color       = color,
                BlurRadius  = blur,
                ShadowDepth = 0,
                Opacity     = opacity
            };
        }

        public object ConvertBack(object value, Type targetType,
                                  object parameter, System.Globalization.CultureInfo culture)
            => throw new NotSupportedException();
    }

    /// <summary>
    /// Converts a double value to True if it exceeds 75 (high usage threshold).
    /// Used for DataTrigger on ProgressBar to switch to yellow fill.
    /// </summary>
    public sealed class HighUsageConverter : System.Windows.Data.IValueConverter
    {
        public static readonly HighUsageConverter Instance = new();

        public object Convert(object value, Type targetType,
                              object parameter, System.Globalization.CultureInfo culture)
            => value is double d && d >= 75.0;

        public object ConvertBack(object value, Type targetType,
                                  object parameter, System.Globalization.CultureInfo culture)
            => throw new NotSupportedException();
    }
}


// ═══════════════════════════════════════════════════════════════════
//  SentinelHud.xaml.cs  — Code-Behind (minimal, MVVM-compliant)
// ═══════════════════════════════════════════════════════════════════

namespace VibeToolkit.HUD.Sentinel
{
    using System.Runtime.InteropServices;
    using System.Windows;
    using System.Windows.Input;
    using System.Windows.Interop;

    /// <summary>
    /// Code-behind for SentinelHud.xaml.
    /// Handles:
    ///   · Extended Window Style (WS_EX_TRANSPARENT) for click-through on the root canvas.
    ///   · DragMove wiring for the drag handle and panel headers.
    ///
    /// MVVM note: event handlers here are purely view concerns (window chrome
    /// and OS-level hit-testing); they do NOT contain business logic.
    /// </summary>
    public partial class SentinelHud : Window
    {
        // Win32: WS_EX_TRANSPARENT makes the window invisible to mouse hits
        private const int GWL_EXSTYLE        = -20;
        private const int WS_EX_TRANSPARENT  = 0x00000020;
        private const int WS_EX_LAYERED      = 0x00080000;
        private const int WS_EX_TOOLWINDOW   = 0x00000080;

        [DllImport("user32.dll")]
        private static extern int GetWindowLong(IntPtr hwnd, int index);

        [DllImport("user32.dll")]
        private static extern int SetWindowLong(IntPtr hwnd, int index, int newStyle);

        public SentinelHud()
        {
            InitializeComponent();

            // Dispose ViewModel when window closes
            Closed += (_, _) =>
            {
                if (DataContext is IDisposable d) d.Dispose();
            };

            // Register converter instances as resources
            Resources[nameof(PingColorConverter)]   = PingColorConverter.Instance;
            Resources[nameof(PingGlowConverter)]    = PingGlowConverter.Instance;
            Resources[nameof(StatusColorConverter)] = StatusColorConverter.Instance;
            Resources[nameof(StatusGlowConverter)]  = StatusGlowConverter.Instance;
            Resources[nameof(HighUsageConverter)]   = HighUsageConverter.Instance;
        }

        /// <summary>
        /// After the window handle is created, apply extended styles so that
        /// the transparent root canvas passes clicks through to windows below.
        /// Panels override IsHitTestVisible=True and absorb their own clicks.
        /// </summary>
        protected override void OnSourceInitialized(EventArgs e)
        {
            base.OnSourceInitialized(e);

            var hwnd = new WindowInteropHelper(this).Handle;
            int style = GetWindowLong(hwnd, GWL_EXSTYLE);

            // Make the window layered + transparent so click-through works
            SetWindowLong(hwnd, GWL_EXSTYLE,
                          style | WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW);
        }

        // ── Click-through root: absorb nothing ───────────────────────
        private void OnRootMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            // Root grid is click-through — do not call DragMove here.
            // Only named drag zones initiate DragMove.
        }

        // ── Panel header drag ────────────────────────────────────────
        private void OnPanelMouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ButtonState == MouseButtonState.Pressed &&
                e.ChangedButton == MouseButton.Left)
            {
                // Individual panels don't move — they're fixed.
                // If you want movable panels, attach TranslateTransform here.
                e.Handled = true;
            }
        }

        // ── Drag handle: moves the entire window ─────────────────────
        private void OnDragHandleMouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ButtonState == MouseButtonState.Pressed)
            {
                // Remove WS_EX_TRANSPARENT temporarily to allow DragMove
                var hwnd = new WindowInteropHelper(this).Handle;
                int style = GetWindowLong(hwnd, GWL_EXSTYLE);
                SetWindowLong(hwnd, GWL_EXSTYLE, style & ~WS_EX_TRANSPARENT);

                try
                {
                    if (WindowState == WindowState.Maximized)
                        WindowState = WindowState.Normal;
                    DragMove();
                }
                finally
                {
                    // Re-apply click-through after drag completes
                    SetWindowLong(hwnd, GWL_EXSTYLE, style | WS_EX_TRANSPARENT);
                }

                e.Handled = true;
            }
        }
    }
}
