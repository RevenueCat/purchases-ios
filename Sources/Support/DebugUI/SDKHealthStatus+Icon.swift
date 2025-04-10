import SwiftUI

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
