import SwiftUI
import Foundation
import RevenueCat

#if DEBUG
@MainActor @Observable final class HealthViewModel {
    var products = [ProductViewModel]()
    var offerings = [OfferingViewModel]()

    var isfetchingHealthReport: Bool = false

    func fetchHealthReport() async {
        defer { isfetchingHealthReport = false }
        isfetchingHealthReport = true

        let report = await PurchasesDiagnostics.default.healthReport()
        let reportProducts = report.products
        let identifiers = Set(reportProducts.map(\.identifier) + report.offerings.flatMap { $0.packages.map(\.productIdentifier) })
        let storeProducts = await Purchases.shared.products(Array(identifiers))
            .reduce(into: [String: StoreProduct]()) { partialResult, storeProduct in
                partialResult[storeProduct.productIdentifier] = storeProduct
            }

        self.offerings = report.offerings.map { offering in
            OfferingViewModel(
                identifier: offering.identifier,
                status: offering.status,
                products: offering.packages.map { package in
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
        self.products = reportProducts.map { product in
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
