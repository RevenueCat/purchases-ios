import RevenueCat
import SwiftUI

struct OfferingViewModel: Identifiable, Equatable {
    var id: String { identifier }
    let identifier: String
    let status: PurchasesDiagnostics.SDKHealthCheckStatus
    let packages: [PackageViewModel]

    var icon: String {
        status.icon
    }

    var color: Color {
        status.color
    }
}
