import WidgetKit
import SwiftUI

@main
struct OvernodeWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        OvernodeDailyRewardWidget()
        OvernodeServerRenewalWidget()
    }
}

