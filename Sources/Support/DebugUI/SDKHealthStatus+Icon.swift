import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension PurchasesDiagnostics.SDKHealthStatus {
    var icon: some View {
        switch self {
        case let .healthy(warnings):
            Image(systemName: warnings.count > 0 ? "checkmark.circle.badge.questionmark.fill" : "checkmark.circle.fill")
                .foregroundColor(.green)
        case .unhealthy:
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
        }

    }
}
