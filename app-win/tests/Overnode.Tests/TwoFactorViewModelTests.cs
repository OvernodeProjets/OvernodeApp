using Overnode.App.ViewModels;

namespace Overnode.Tests;

public class TwoFactorViewModelTests
{
    public void Test_CanVerify_Requires_Minimum_Six_Characters()
    {
        var vm = new TwoFactorViewModel();

        vm.Code = "";
        Assert.IsFalse(vm.CanVerify);

        vm.Code = "12345";
        Assert.IsFalse(vm.CanVerify);

        vm.Code = "123456";
        Assert.IsTrue(vm.CanVerify);

        vm.Code = "backup-code-12345";
        Assert.IsTrue(vm.CanVerify);
    }

    public void Test_Cancel_Resets_Code_And_Error()
    {
        var vm = new TwoFactorViewModel
        {
            Code = "123456",
            ErrorMessage = "Test Error"
        };

        bool cancelled = false;
        vm.VerificationCancelled += () => cancelled = true;

        vm.CancelCommand.Execute(null);

        Assert.AreEqual(string.Empty, vm.Code);
        Assert.IsNull(vm.ErrorMessage);
        Assert.IsTrue(cancelled);
    }
}
