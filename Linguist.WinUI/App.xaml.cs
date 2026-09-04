using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;

namespace Linguist.WinUI;

/// <summary>
/// WinUI 3 应用程序生命周期与核心入口
/// </summary>
public partial class App : Application
{
    private Window? _mainWindow;
    public static DispatcherQueue? DispatcherQueue { get; private set; }

    public App()
    {
        this.InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _mainWindow = new MainWindow();
        DispatcherQueue = _mainWindow.DispatcherQueue;
        _mainWindow.Activate();
    }
}
