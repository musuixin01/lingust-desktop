using System;
using System.Runtime.InteropServices;

namespace Linguist.WinUI.Interop;

/// <summary>
/// Win32 API 与桌面窗口管理器 (DWM) 深度互操作封装
/// 提供大圆角控制、无边框透明窗口、系统磨砂亚克力/云母背景、以及原生顺滑无卡顿拖拽
/// </summary>
public static class Win32
{
    public const int WM_NCLBUTTONDOWN = 0x00A1;
    public const int HTCAPTION = 0x0002;

    public const int GWL_STYLE = -16;
    public const int GWL_EXSTYLE = -20;

    public const long WS_POPUP = 0x80000000L;
    public const long WS_VISIBLE = 0x10000000L;
    public const long WS_THICKFRAME = 0x00040000L;
    public const long WS_MINIMIZEBOX = 0x00020000L;
    public const long WS_MAXIMIZEBOX = 0x00010000L;
    public const long WS_CAPTION = 0x00C00000L;

    public const long WS_EX_LAYERED = 0x00080000L;
    public const long WS_EX_TRANSPARENT = 0x00000020L;
    public const long WS_EX_TOOLWINDOW = 0x00000080L;
    public const long WS_EX_TOPMOST = 0x00000008L;

    // DWM 窗口属性枚举 (Windows 11 SDK)
    public enum DWMWINDOWATTRIBUTE
    {
        DWMWA_NCRENDERING_ENABLED = 1,
        DWMWA_NCRENDERING_POLICY = 2,
        DWMWA_EXTENDED_FRAME_BOUNDS = 9,
        DWMWA_USE_IMMERSIVE_DARK_MODE = 20,
        DWMWA_WINDOW_CORNER_PREFERENCE = 33,
        DWMWA_BORDER_COLOR = 34,
        DWMWA_CAPTION_COLOR = 35,
        DWMWA_TEXT_COLOR = 36,
        DWMWA_SYSTEMBACKDROP_TYPE = 38
    }

    // Windows 11 DWM 圆角偏好设置
    public enum DWM_WINDOW_CORNER_PREFERENCE
    {
        DWMWCP_DEFAULT = 0,
        DWMWCP_DONOTROUND = 1,
        DWMWCP_ROUND = 2,          // 启用标准圆角 (32px / 标准大圆角)
        DWMWCP_ROUNDSMALL = 3      // 启用小圆角 (8px)
    }

    // Windows 11 系统级背景材质 (System Backdrop)
    public enum DWM_SYSTEMBACKDROP_TYPE
    {
        DWMSBT_AUTO = 0,
        DWMSBT_NONE = 1,            // 纯透明通道 (用于 XAML 自绘 Apple Liquid Glass)
        DWMSBT_MAINWINDOW = 2,      // Mica (云母材质)
        DWMSBT_TRANSIENTWINDOW = 3, // Acrylic (亚克力磨砂玻璃)
        DWMSBT_TABBEDWINDOW = 4     // Mica Alt
    }

    [DllImport("dwmapi.dll", PreserveSig = true)]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, DWMWINDOWATTRIBUTE attr, ref int attrValue, int attrSize);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

    public const uint SWP_NOMOVE = 0x0002;
    public const uint SWP_NOSIZE = 0x0001;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;

    /// <summary>
    /// 一键触发原生 Win32 标题栏级别的顺滑窗口拖拽
    /// </summary>
    public static void DragWindow(IntPtr hwnd)
    {
        if (hwnd == IntPtr.Zero) return;
        ReleaseCapture();
        SendMessage(hwnd, WM_NCLBUTTONDOWN, (IntPtr)HTCAPTION, IntPtr.Zero);
    }

    /// <summary>
    /// 启用 Windows 11 原生大圆角模式并去除系统 1px 黑色生硬矩形框
    /// </summary>
    public static void ConfigureModernWindowBorder(IntPtr hwnd, bool isDark = true)
    {
        if (hwnd == IntPtr.Zero) return;

        // 1. 设置深色模式跟随
        int darkMode = isDark ? 1 : 0;
        DwmSetWindowAttribute(hwnd, DWMWINDOWATTRIBUTE.DWMWA_USE_IMMERSIVE_DARK_MODE, ref darkMode, sizeof(int));

        // 2. 启用 DWMWCP_ROUND 大圆角
        int cornerPref = (int)DWM_WINDOW_CORNER_PREFERENCE.DWMWCP_ROUND;
        DwmSetWindowAttribute(hwnd, DWMWINDOWATTRIBUTE.DWMWA_WINDOW_CORNER_PREFERENCE, ref cornerPref, sizeof(int));

        // 3. 将系统边框颜色设为 0xFFFFFFFE (DWMWA_COLOR_NONE)，禁止 DWM 擅自画出系统硬边
        int noneColor = unchecked((int)0xFFFFFFFE);
        DwmSetWindowAttribute(hwnd, DWMWINDOWATTRIBUTE.DWMWA_BORDER_COLOR, ref noneColor, sizeof(int));

        // 4. 背景启用系统级透明/亚克力通道
        int backdropType = (int)DWM_SYSTEMBACKDROP_TYPE.DWMSBT_TRANSIENTWINDOW;
        DwmSetWindowAttribute(hwnd, DWMWINDOWATTRIBUTE.DWMWA_SYSTEMBACKDROP_TYPE, ref backdropType, sizeof(int));
    }

    /// <summary>
    /// 切换窗口置顶状态
    /// </summary>
    public static void SetAlwaysOnTop(IntPtr hwnd, bool isTopmost)
    {
        if (hwnd == IntPtr.Zero) return;
        SetWindowPos(hwnd, isTopmost ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
}
