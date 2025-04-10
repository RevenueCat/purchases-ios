import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension PurchasesDiagnostics.SDKHealthCheckStatus {
    var icon: some View {
        switch self {
        case .passed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .warning:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        }
    }
}
