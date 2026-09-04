using System;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Linguist.WinUI.Interop;
using Linguist.WinUI.ViewModels;

namespace Linguist.WinUI.Views;

public sealed partial class PillView : UserControl
{
    public TranslatorViewModel ViewModel { get; set; } = null!;
    public IntPtr WindowHandle { get; set; } = IntPtr.Zero;

    public PillView()
    {
        this.InitializeComponent();
    }

    private void OnPillPointerPressed(object sender, PointerRoutedEventArgs e)
    {
        // 允许通过按住药丸背景空白处直接原生顺滑拖拽窗口
        if (WindowHandle != IntPtr.Zero)
        {
            Win32.DragWindow(WindowHandle);
        }
    }
}
