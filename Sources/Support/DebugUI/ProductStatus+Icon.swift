import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension PurchasesDiagnostics.ProductStatus {
    var icon: some View {
        switch self {
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .couldNotCheck, .unknown:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.gray)
        case .notFound:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .actionInProgress, .needsAction:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        }
    }
}
