using System;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Linguist.WinUI.Interop;
using Linguist.WinUI.ViewModels;

namespace Linguist.WinUI.Views;

public sealed partial class CardView : UserControl
{
    public TranslatorViewModel ViewModel { get; set; } = null!;
    public IntPtr WindowHandle { get; set; } = IntPtr.Zero;

    public CardView()
    {
        this.InitializeComponent();
    }

    private void OnHeaderPointerPressed(object sender, PointerRoutedEventArgs e)
    {
        // 允许通过按住卡片顶部标题栏直接触发 Win32 原生无感顺滑拖拽
        if (WindowHandle != IntPtr.Zero)
        {
            Win32.DragWindow(WindowHandle);
        }
    }

    private void OnSmartSelectTogglePressed(object sender, PointerRoutedEventArgs e)
    {
        ViewModel?.ToggleSmartSelect();
    }
}
