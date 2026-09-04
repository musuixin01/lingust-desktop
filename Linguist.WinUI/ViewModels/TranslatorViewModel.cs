using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Linguist.WinUI.Models;

namespace Linguist.WinUI.ViewModels;

/// <summary>
/// 悬浮翻译卡片与药丸视图的核心 UI 状态机
/// </summary>
public partial class TranslatorViewModel : ObservableObject
{
    [ObservableProperty]
    private bool isPillMode = false;

    [ObservableProperty]
    private string sourceText = "Efficient";

    [ObservableProperty]
    private string sourceLang = "英语";

    [ObservableProperty]
    private string targetLang = "中文";

    [ObservableProperty]
    private string engineName = "Gemini";

    [ObservableProperty]
    private bool isPinned = false;

    [ObservableProperty]
    private bool isLoading = false;

    [ObservableProperty]
    private bool isCopied = false;

    [ObservableProperty]
    private bool isFavorite = false;

    [ObservableProperty]
    private bool selectionTranslationEnabled = true;

    [ObservableProperty]
    private int fontSizePercent = 92;

    [ObservableProperty]
    private TranslationResultModel currentResult = new();

    public string DimensionText => IsPillMode ? "340×48" : "390×520";

    [RelayCommand]
    public void SwitchToPill()
    {
        IsPillMode = true;
        OnPropertyChanged(nameof(DimensionText));
    }

    [RelayCommand]
    public void SwitchToCard()
    {
        IsPillMode = false;
        OnPropertyChanged(nameof(DimensionText));
    }

    [RelayCommand]
    public void TogglePill()
    {
        IsPillMode = !IsPillMode;
        OnPropertyChanged(nameof(DimensionText));
    }

    [RelayCommand]
    public void SwapLanguages()
    {
        (SourceLang, TargetLang) = (TargetLang, SourceLang);
    }

    [RelayCommand]
    public void ClearText()
    {
        SourceText = string.Empty;
    }

    [RelayCommand]
    public void TogglePin()
    {
        IsPinned = !IsPinned;
    }

    [RelayCommand]
    public void ToggleFavorite()
    {
        IsFavorite = !IsFavorite;
        if (CurrentResult != null)
        {
            CurrentResult.IsFavorite = IsFavorite;
        }
    }

    [RelayCommand]
    public void ToggleSmartSelect()
    {
        SelectionTranslationEnabled = !SelectionTranslationEnabled;
    }

    [RelayCommand]
    public async Task CopyTranslationAsync()
    {
        IsCopied = true;
        await Task.Delay(1500);
        IsCopied = false;
    }

    [RelayCommand]
    public void RefreshTranslation()
    {
        IsLoading = true;
        Task.Run(async () =>
        {
            await Task.Delay(400);
            App.DispatcherQueue?.TryEnqueue(() =>
            {
                IsLoading = false;
            });
        });
    }
}
