using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Data;
using Microsoft.UI.Xaml.Media;

namespace Linguist.WinUI.Converters;

public class BoolToColorConverter : IValueConverter
{
    public SolidColorBrush TrueBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 59, 130, 246));
    public SolidColorBrush FalseBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 148, 163, 184));

    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? TrueBrush : FalseBrush;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class BoolToFillConverter : IValueConverter
{
    public SolidColorBrush TrueBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 59, 130, 246));
    public SolidColorBrush FalseBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(0, 0, 0, 0));

    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? TrueBrush : FalseBrush;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class BoolToFavoriteColorConverter : IValueConverter
{
    public SolidColorBrush TrueBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 251, 191, 36));
    public SolidColorBrush FalseBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 148, 163, 184));

    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? TrueBrush : FalseBrush;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class BoolToFavoriteFillConverter : IValueConverter
{
    public SolidColorBrush TrueBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 251, 191, 36));
    public SolidColorBrush FalseBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(0, 0, 0, 0));

    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? TrueBrush : FalseBrush;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class BoolToSwitchBackgroundConverter : IValueConverter
{
    public SolidColorBrush TrueBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(255, 59, 130, 246));
    public SolidColorBrush FalseBrush { get; set; } = new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(60, 255, 255, 255));

    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? TrueBrush : FalseBrush;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class BoolToSwitchAlignConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? HorizontalAlignment.Right : HorizontalAlignment.Left;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? Visibility.Visible : Visibility.Collapsed;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}

public class InverseBoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? Visibility.Collapsed : Visibility.Visible;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language) => throw new NotImplementedException();
}
