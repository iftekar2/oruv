import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { configuration in
            TotalActivityView(configuration: configuration)
        }
        InsightsActivityReport { configuration in
            InsightsActivityView(configuration: configuration)
        }
        AnchorTimeSavedReport { configuration in
            AnchorTimeSavedView(configuration: configuration)
        }
    }
}
