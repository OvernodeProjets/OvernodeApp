import WidgetKit
import SwiftUI

@main
struct OvernodeWidgetBundle: WidgetBundle {
    var body: some Widget {
        OvernodeDailyRewardWidget()
        OvernodeServerRenewalWidget()
    }
}

