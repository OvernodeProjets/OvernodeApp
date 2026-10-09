using System;
using Overnode.App.Localization;
using Overnode.App.Services;

namespace Overnode.Tests;

public class Program
{
    [STAThread]
    public static int Main(string[] args)
    {
        Console.WriteLine("=======================================");
        Console.WriteLine("Overnode Windows Native - Test Runner");
        Console.WriteLine("=======================================\n");
        Console.Out.Flush();

        int passed = 0;
        int failed = 0;


        void Run(string name, Action test)
        {
            try
            {
                Console.Write($"Running: {name}... ");
                Console.Out.Flush();
                test();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("PASSED");
                Console.ResetColor();
                Console.Out.Flush();
                passed++;
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"FAILED: {ex.Message}");
                Console.ResetColor();
                Console.Out.Flush();
                failed++;
            }
        }

        // 1. Serialization Tests (pure models)
        var modelTests = new ModelSerializationTests();
        Run("AuthStateResponse 2FA Pending Deserialization", modelTests.Test_AuthStateResponse_Deserialization_With_2FA_Pending);
        Run("AuthStateResponse Authenticated Deserialization", modelTests.Test_AuthStateResponse_Deserialization_Authenticated);
        Run("User Coins PropertyChanged Notification", modelTests.Test_User_Coins_PropertyChanged_Event);
        Run("CoinsResponse String/Number Deserialization", modelTests.Test_CoinsResponse_AllowReadingFromString);
        Run("ServerNode Flexible Types Deserialization", modelTests.Test_ServerNode_Deserialization_Flexible_Types);
        Run("ServerLocation Flexible Types Deserialization", modelTests.Test_ServerLocation_Deserialization_Flexible_Types);
        Run("LocationHelper Real Node Matching", modelTests.Test_LocationHelper_IsMatch_Real_Nodes);
        Run("CreateServerResult Deserialization No Collision", modelTests.Test_CreateServerResult_Deserialization_CaseInsensitive);

        // 2. DPAPI Tests
        var persistenceTests = new SessionPersistenceTests();
        Run("DPAPI Save and Load Cookies", persistenceTests.Test_DPAPI_Save_And_Load_Cookies);
        Run("CookieContainer Domains", persistenceTests.Test_CookieContainer_Domains);

        // 3. 2FA ViewModel Tests
        var twoFactorTests = new TwoFactorViewModelTests();
        Run("2FA CanVerify requires minimum 6 characters", twoFactorTests.Test_CanVerify_Requires_Minimum_Six_Characters);
        Run("2FA Cancel resets code and error", twoFactorTests.Test_Cancel_Resets_Code_And_Error);
        Run("2FA Verify with OnVerifySuccessAsync callback", twoFactorTests.Test_Verify_With_OnVerifySuccessAsync);

        // 4. Server & Dashboard Tests
        var serverTests = new ServerAndDashboardTests();
        Run("ServerInstance Permissions Owner", serverTests.Test_ServerInstance_Permissions_Owner);
        Run("ServerInstance Permissions Subuser", serverTests.Test_ServerInstance_Permissions_Subuser);
        Run("PteroServerWrapper Deserialization to ServerInstance", serverTests.Test_PteroServerWrapper_Deserialization);
        Run("ResourcesResponse Calculations (RAM, CPU, Disk, Servers)", serverTests.Test_ResourcesResponse_Calculations);
        Run("ServerInstance Reactive State and Resources Notifications", serverTests.Test_ServerInstance_Reactive_State_And_Resources_Notifications);

        // 5. Detailed Server Management Tests
        var mgmtTests = new ServerManagementTests();
        Run("ServerPowerSignal String & Glyph Extensions", mgmtTests.Test_ServerPowerSignal_Extensions);
        Run("ServerRenewalStatus Time Remaining Calculation", mgmtTests.Test_ServerRenewalStatus_TimeCalculation);
        Run("FlexibleRenewalStringConverter Object Payload", mgmtTests.Test_FlexibleRenewalStringConverter_ObjectPayload);
        Run("FlexibleRenewalStringConverter String & Number Payload", mgmtTests.Test_FlexibleRenewalStringConverter_StringAndNumberPayload);
        Run("ServerRenewalActionResponse Error Payload & Duration", mgmtTests.Test_ServerRenewalActionResponse_ErrorPayload);
        Run("ServerTab macOS Parity (9 tabs, glyphs, i18n)", mgmtTests.Test_ServerTab_Parity_AllNineTabs);
        Run("InstalledPluginsResponse Deserialization", mgmtTests.Test_InstalledPluginsResponse_Deserialization);
        Run("Spigot Search Deserialization (numeric ID & objects)", mgmtTests.Test_SpigotPluginSearch_Deserialization_With_NumericId_And_Objects);
        Run("ActivityLogsResponse Deserialization", mgmtTests.Test_ActivityLogsResponse_Deserialization);
        Run("QuickActionServerStorage Save/Load/Clear", mgmtTests.Test_QuickActionServerStorage);
        Run("DiscordRPCService Initialization", mgmtTests.Test_DiscordRPCService_Initialization);
        Run("ServerWebSocketManager Initialization", mgmtTests.Test_ServerWebSocketManager_Initialization);
        Run("ServerInstance Identifier Fallback (UUID/ID)", mgmtTests.Test_ServerInstance_IdentifierFallback);
        Run("PteroServerWrapper UUID Fallback", mgmtTests.Test_PteroServerWrapper_UuidFallback);
        Run("Server Power State Transitions (Start/Stop)", mgmtTests.Test_ServerPower_StateTransitions);
        Run("ServerFileItem Size & Icon Formatting", mgmtTests.Test_ServerFileItem_Formatting);
        Run("PteroFileList Response Deserialization", mgmtTests.Test_PteroFileList_Deserialization);
        Run("ServerSubdomain & ServerSubuser Models", mgmtTests.Test_ServerSubdomain_And_Subuser);
        Run("ServerDetailViewModel Demo Mode Initialization", mgmtTests.Test_ServerDetailViewModel_DemoMode);
        Run("ServerFilesService NormalizeServerFilePath (Pterodactyl root parity)", mgmtTests.Test_ServerFilesService_NormalizeServerFilePath);

        // 6. Server Deployment & Creation Tests
        var deployTests = new ServerDeploymentTests();
        Run("LocationHelper Formatting & Matching", deployTests.Test_LocationHelper_FormattingAndMatching);
        Run("CreateServerViewModel Name Validation", deployTests.Test_CreateServerViewModel_Validation);
        Run("CreateServerViewModel Deploy Flow", () => deployTests.Test_CreateServerViewModel_DeployFlowAsync().GetAwaiter().GetResult());

        // 7. Localization Tests
        var locTests = new LocalizationTests();
        Run("LocalizationManager French & English Translations", () =>
        {
            var loc = LocalizationManager.Instance;
            loc.SetLanguage(AppLanguage.Fr);
            Assert.AreEqual("Bienvenue sur Overnode", loc["auth_title"]);
            Assert.AreEqual("Double Facteur (2FA)", loc["2fa_title"]);
            Assert.AreEqual("Tableau de Bord", loc["dashboard_title"]);
            Assert.AreEqual("Mémoire RAM", loc["resource_ram"]);
            Assert.AreEqual("Mes Serveurs", loc["dashboard_servers_title"]);

            loc.SetLanguage(AppLanguage.En);
            Assert.AreEqual("Welcome to Overnode", loc["auth_title"]);
            Assert.AreEqual("Two-Factor Authentication", loc["2fa_title"]);

            // Revert to French
            loc.SetLanguage(AppLanguage.Fr);
        });
        Run("Localization FR/EN Key Parity & No Duplicates", locTests.Test_FrEn_KeyParity_And_No_Duplicates);
        Run("Localization No console.overnode.fr In Translations", locTests.Test_NoConsoleOvernodeFrInTranslations);
        Run("Localization All Critical Keys Exist In FR and EN", locTests.Test_AllCriticalKeysExist);
        Run("Localization Formatting & Persistence", locTests.Test_Formatting_And_Persistence);
        Run("Localization Model Localized Properties", locTests.Test_ModelLocalizedProperties);

        // 8. Secondary Modules Tests (Wallet, DailyReward, Store, Support, NavigationTabs)
        var secondaryTests = new SecondaryModulesTests();
        Run("Wallet Models & Balances", secondaryTests.Test_Wallet_Models_And_Balances);
        Run("DailyReward Models & Status", secondaryTests.Test_DailyReward_Models_And_Status);
        Run("Store Pricing & Bundles", secondaryTests.Test_Store_Pricing_And_Bundles);
        Run("Support Ticket Models & Messages", secondaryTests.Test_Support_Ticket_Models);
        Run("NavigationTab Glyphs & Keys", secondaryTests.Test_NavigationTabs_And_Glyphs);
        Run("ExternalEditorManager Settings & Toggle", secondaryTests.Test_ExternalEditorManager_Settings_And_Toggle);
        Run("ExternalEditorManager Resolution & Detection", secondaryTests.Test_ExternalEditorManager_Resolution_And_Detection);
        Run("ExternalEditorManager Save & Sync", () => secondaryTests.Test_ExternalEditorManager_Save_And_Sync().GetAwaiter().GetResult());
        Run("Subdomain Domain Restriction (overnode.fr)", () => secondaryTests.Test_Subdomain_Domain_Restriction().GetAwaiter().GetResult());

        // 9. In-App Updater Tests
        UpdateTests.RunAll(Run);

        // 10. Windows Quick Actions & Tray Tests
        var trayTests = new TrayQuickActionTests();
        Run("QuickAction ServerStorage Set & Get", trayTests.Test_QuickActionServerStorage_Basic);
        Run("QuickAction ServerStorage Notification", trayTests.Test_QuickActionServerStorage_Notification);
        Run("TrayIconManager UpdateServers & Active Server", trayTests.Test_TrayIconManager_UpdateServersAndActiveServer);
        Run("TrayIconManager Multiple Servers Switching", trayTests.Test_TrayIconManager_MultipleServersSwitching);
        Run("TrayIconManager Tooltip Formatting", trayTests.Test_TrayIconManager_TooltipFormatting);
        Run("TrayIconManager Localized Server States", trayTests.Test_TrayIconManager_LocalizedServerStates);
        Run("TrayIconManager Menu Command Execution", trayTests.Test_TrayIconManager_MenuCommandExecution);
        Run("QuickAction Translations Exist (FR & EN)", trayTests.Test_QuickActionTranslationsExist_FrenchAndEnglish);

        // 11. Console Color & Copy Tests
        var consoleColorTests = new ConsoleColorTests();
        Run("ConsoleColorHelper ANSI Parsing Basic Colors", consoleColorTests.Test_AnsiParsing_BasicColors);
        Run("ConsoleColorHelper Semantic Coloring Without ANSI", consoleColorTests.Test_SemanticColoring_WithoutAnsi);
        Run("ConsoleColorHelper Strip ANSI & Plain Text", consoleColorTests.Test_StripAnsi_And_ToPlainText);
        Run("ConsoleColorHelper HTML Fragment & Clipboard Wrap", consoleColorTests.Test_ToHtmlFragment_PreservesColors);
        Run("ConsoleColorHelper RTF Color Table", consoleColorTests.Test_ToRtf_ContainsColorTable);
        Run("ConsoleColorHelper Discord ANSI Formatting", consoleColorTests.Test_ToDiscordAnsi);
        Run("TrayIconManager Disposal Idempotence", consoleColorTests.Test_TrayIconManager_DisposalIdempotence);

        // 12. File Upload Security Tests
        FileUploadSecurityTests.RunAll(Run);

        // 13. Folder Sync Tests
        FolderSyncTests.RunAll(Run);

        // 14. Easter Egg Tests (macOS Parity & Windows Ctrl+T)
        var easterEggTests = new EasterEggTests();
        Run("EasterEgg Assets Preloaded & Available (12 poses)", easterEggTests.Test_EasterEgg_Assets_Preloaded_And_Available);
        Run("EasterEgg Excluded Forbidden Image Not Present", easterEggTests.Test_Excluded_Image_Not_Present);
        Run("EasterEgg Audio Resolution & Properties", easterEggTests.Test_EasterEgg_Audio_Resolution_And_Properties);
        Run("EasterEgg Phases Timing & Non-Empty Titles", easterEggTests.Test_EasterEgg_Phases_Timing_And_Titles);
        Run("EasterEgg Localization Active Switch (FR & EN)", easterEggTests.Test_EasterEgg_Localization_Active_Switch);
        Run("EasterEgg Shortcut & Rules Parity (Ctrl+T in Settings)", easterEggTests.Test_EasterEgg_Shortcut_And_Rules_Parity);

        // 15. God Pack Customization Tests (macOS Parity & Windows Ctrl+D)
        var godPackTests = new GodPackThemeTests();
        Run("GodPack 9 Community Presets Validity & Colors", godPackTests.Test_All_9_Presets_Validity);
        Run("GodPack ColorHexHelper Normalization & Parsing", godPackTests.Test_ColorHexHelper_Normalization);
        Run("GodPack BundleStatus & Updater DTO Deserialization", godPackTests.Test_BundleStatus_And_Updater_Deserialization);
        Run("GodPack AppThemeConfig Serialization Round-Trip (.overnode.app)", godPackTests.Test_ThemeConfig_Serialization_Parity);
        Run("GodPack ThemeManager Preset Application & Reset", godPackTests.Test_ThemeManager_Preset_And_Reset);
        Run("GodPack ThemeManager Disk Persistence Round-Trip", godPackTests.Test_ThemeManager_Persistence_RoundTrip);
        Run("GodPack ThemeManager Resolved Landing Tabs", godPackTests.Test_ThemeManager_ResolvedLandingTab);
        Run("GodPack Localization Parity (FR & EN + Ctrl+D Shortcut)", godPackTests.Test_GodPack_Localization_Parity_FR_EN);

        Console.WriteLine($"\n---------------------------------------");
        Console.WriteLine($"Total: {passed + failed} | Passed: {passed} | Failed: {failed}");
        Console.WriteLine("=======================================");
        Console.Out.Flush();

        return failed == 0 ? 0 : 1;
    }
}
