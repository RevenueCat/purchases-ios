import Foundation

extension PurchasesDiagnostics.InvalidProductErrorPayload {
    var statusMessage: String {
        switch self.status {
        case .ok:
            return "Available for production purchases."
        case .couldNotCheck:
            return self.description
        case .notFound:
            return "Product not found in App Store Connect. You need to create a product with identifier: '\(self.identifier)' in App Store Connect to use it for production purchases."
        case .actionInProgress:
            return "Some process is ongoing and needs to be completed before using this product in production purchases, controlled either by the developer or by Apple (state: \(self.description))"
        case .needsAction:
            return "This product's status (\(self.description)) requires you to take action in App Store Connect before using it in production purchases."
        case .unknown:
            return "We could not check the status of your product using the App Store Connect API. Please check the app's credentials in the dashboard and try again."
        }
    }
}
