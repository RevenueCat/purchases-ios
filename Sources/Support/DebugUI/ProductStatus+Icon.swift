import SwiftUI

extension PurchasesDiagnostics.ProductStatus {
    var icon: some View {
        switch self {
        case .ok:
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
