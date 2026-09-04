using System;
using System.ComponentModel;
using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Windows.Graphics;
using Linguist.WinUI.Interop;
using Linguist.WinUI.ViewModels;

namespace Linguist.WinUI;

/// <summary>
/// 桌面主宿主窗口：集成 Win32 DWM 原生无边框大圆角透明亚克力窗口与 AppWindow 尺寸平滑联动
/// </summary>
public sealed partial class MainWindow : Window
{
    public TranslatorViewModel ViewModel { get; } = new();
    private readonly IntPtr _hwnd;
    private readonly AppWindow _appWindow;

    public MainWindow()
    {
        this.InitializeComponent();

        // 获取 Win32 原生 HWND 句柄
        _hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        var windowId = Win32Interop.GetWindowIdFromWindow(_hwnd);
        _appWindow = AppWindow.GetFromWindowId(windowId);

        // 1. 将内容扩展至整个标题栏，消除 Windows 默认生硬顶栏
        _appWindow.TitleBar.ExtendsContentIntoTitleBar = true;
        _appWindow.TitleBar.ButtonBackgroundColor = Colors.Transparent;
        _appWindow.TitleBar.ButtonInactiveBackgroundColor = Colors.Transparent;
        _appWindow.TitleBar.ButtonHoverBackgroundColor = Colors.Transparent;
        _appWindow.TitleBar.ButtonPressedBackgroundColor = Colors.Transparent;

        // 2. 调用 DWM API 配置 Windows 11 原生大圆角与消隐硬边
        Win32.ConfigureModernWindowBorder(_hwnd, isDark: true);

        // 3. 注入数据模型与窗口句柄至子视图
        CardControl.ViewModel = ViewModel;
        CardControl.WindowHandle = _hwnd;

        PillControl.ViewModel = ViewModel;
        PillControl.WindowHandle = _hwnd;

        // 4. 初始化卡片默认物理尺寸 (390×520 + 边距缓冲)
        _appWindow.Resize(new SizeInt32(410, 540));

        // 5. 监听卡片与药丸模式切换事件，平滑重设窗口尺寸
        ViewModel.PropertyChanged += OnViewModelPropertyChanged;
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(ViewModel.IsPillMode))
        {
            if (ViewModel.IsPillMode)
            {
                // 切换为悬浮药丸胶囊尺寸
                _appWindow.Resize(new SizeInt32(360, 58));
            }
            else
            {
                // 恢复为完整大圆角卡片尺寸
                _appWindow.Resize(new SizeInt32(410, 540));
            }
        }
        else if (e.PropertyName == nameof(ViewModel.IsPinned))
        {
            Win32.SetAlwaysOnTop(_hwnd, ViewModel.IsPinned);
        }
    }
}
