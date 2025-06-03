import Foundation
import RevenueCat
import SwiftUI

extension PurchasesDiagnostics.SDKHealthError: @retroactive Identifiable {
    public var id: String {
        switch self {
        case .notAuthorizedToMakePayments:
            return "notAuthorizedToMakePayments"
        case .invalidAPIKey:
            return "invalidAPIKey"
        case .noOfferings:
            return "noOfferings"
        case .offeringConfiguration:
            return "offeringConfiguration"
        case .invalidBundleId:
            return "invalidBundleId"
        case .invalidProducts:
            return "invalidProducts"
        case let .unknown(error):
            return "unknown-\(error.localizedDescription)"
        }
    }
}

#if DEBUG
    @MainActor @Observable final class HealthViewModel {
        var products = [ProductViewModel]()
        var offerings = [OfferingViewModel]()

        var isfetchingHealthReport: Bool = false

        var blockingError: PurchasesDiagnostics.SDKHealthError?

        func fetchHealthReport() async {
            defer { isfetchingHealthReport = false }
            isfetchingHealthReport = true

            let report = await PurchasesDiagnostics.default.healthReport()
            if case let .unhealthy(error) = report.status {
                blockingError = error
                return
            }
            blockingError = nil
            let reportProducts = report.products
            let identifiers = Set(reportProducts.map(\.identifier) + report.offerings.flatMap { $0.packages.map(\.productIdentifier) })
            let storeProducts = await Purchases.shared.products(Array(identifiers))
                .reduce(into: [String: StoreProduct]()) { partialResult, storeProduct in
                    partialResult[storeProduct.productIdentifier] = storeProduct
                }

            offerings = report.offerings.map { offering in
                OfferingViewModel(
                    identifier: offering.identifier,
                    status: offering.status,
                    packages: offering.packages.map { package in
                        ProductViewModel(
                            id: package.identifier,
                            status: package.status,
                            title: package.productIdentifier,
                            description: package.description,
                            storeProduct: storeProducts[package.productIdentifier]
                        )
                    }
                )
            }
            products = reportProducts.map { product in
                ProductViewModel(
                    id: product.identifier,
                    status: product.status,
                    title: product.title,
                    description: product.description,
                    storeProduct: storeProducts[product.identifier]
                )
            }
        }
    }
#endif
