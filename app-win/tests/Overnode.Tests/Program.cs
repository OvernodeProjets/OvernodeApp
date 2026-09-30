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

        // 6. Server Deployment & Creation Tests
        var deployTests = new ServerDeploymentTests();
        Run("LocationHelper Formatting & Matching", deployTests.Test_LocationHelper_FormattingAndMatching);
        Run("CreateServerViewModel Name Validation", deployTests.Test_CreateServerViewModel_Validation);
        Run("CreateServerViewModel Deploy Flow", () => deployTests.Test_CreateServerViewModel_DeployFlowAsync().GetAwaiter().GetResult());

        // 7. Localization Tests
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

        // 8. Secondary Modules Tests (Wallet, DailyReward, Store, Support, NavigationTabs)
        var secondaryTests = new SecondaryModulesTests();
        Run("Wallet Models & Balances", secondaryTests.Test_Wallet_Models_And_Balances);
        Run("DailyReward Models & Status", secondaryTests.Test_DailyReward_Models_And_Status);
        Run("Store Pricing & Bundles", secondaryTests.Test_Store_Pricing_And_Bundles);
        Run("Support Ticket Models & Messages", secondaryTests.Test_Support_Ticket_Models);
        Run("NavigationTab Glyphs & Keys", secondaryTests.Test_NavigationTabs_And_Glyphs);
        Run("ExternalEditorManager Settings & Toggle", secondaryTests.Test_ExternalEditorManager_Settings_And_Toggle);
        Run("Subdomain Domain Restriction (overnode.fr)", () => secondaryTests.Test_Subdomain_Domain_Restriction().GetAwaiter().GetResult());

        // 9. In-App Updater Tests
        UpdateTests.RunAll(Run);

        Console.WriteLine($"\n---------------------------------------");
        Console.WriteLine($"Total: {passed + failed} | Passed: {passed} | Failed: {failed}");
        Console.WriteLine("=======================================");
        Console.Out.Flush();

        return failed == 0 ? 0 : 1;
    }
}
