import DeviceActivity
import ExtensionKit
import FamilyControls
import SwiftUI

@main
@available(iOS 16.0, *)
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
  var body: some DeviceActivityReportScene {
    TotalActivityReport { configuration in
      DailyScreenTimeReportView(configuration: configuration)
    }
  }
}
