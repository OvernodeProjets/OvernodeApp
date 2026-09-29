using System;
using System.Diagnostics;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;

namespace Overnode.App.Views.AFK;

public sealed partial class AFKView : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    public AFKView()
    {
        InitializeComponent();
        _loc.LanguageChanged += (_, _) => UpdateLocalization();
        UpdateLocalization();
    }

    private void UpdateLocalization()
    {
        TitleText.Text = _loc.GetString("afk_title");
        SubtitleText.Text = _loc.GetString("afk_subtitle");
        CardTitle.Text = _loc.GetString("afk_card_title");
        CardRate.Text = _loc.GetString("afk_card_rate");
        CardDesc.Text = _loc.GetString("afk_card_desc");
        Feature1.Text = _loc.GetString("afk_feature_1");
        Feature2.Text = _loc.GetString("afk_feature_2");
        Feature3.Text = _loc.GetString("afk_feature_3");
        BtnOpenText.Text = _loc.GetString("afk_btn_open");
        FootnoteText.Text = _loc.GetString("afk_footnote");
    }

    private void OnOpenWebAFKClicked(object sender, RoutedEventArgs e)
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "https://console.overnode.fr/afk",
                UseShellExecute = true
            });
        }
        catch { }
    }
}
