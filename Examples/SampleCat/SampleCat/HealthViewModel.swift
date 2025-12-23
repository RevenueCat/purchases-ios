import Foundation
import RevenueCat
import SwiftUI

#if DEBUG
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

    /// `HealthViewModel` is used by the SampleCat app to validate your SDK configuration.
    /// If you are looking for an example of how to use RevenueCat in production, check out ``UserViewModel``.
    @MainActor @Observable final class HealthViewModel {
        var products = [ProductViewModel]()
        var offerings = [OfferingViewModel]()

        var isfetchingHealthReport: Bool = false

        var blockingError: PurchasesDiagnostics.SDKHealthError?

        let userViewModel: UserViewModel

        init(userViewModel: UserViewModel) {
            self.userViewModel = userViewModel
        }

        func fetchHealthReport() async {
            defer { isfetchingHealthReport = false }
            isfetchingHealthReport = true

            let report = await PurchasesDiagnostics.default.healthReport()
            if case let .unhealthy(error) = report.status {
                blockingError = error
                return
            }
            blockingError = nil

            async let productViewModels = buildProductViewModels(from: report.products)
            async let offeringViewModels = buildOfferingViewModels(from: report.offerings)

            let (products, offerings) = await (productViewModels, offeringViewModels)

            self.products = products
            self.offerings = offerings
        }

        private func buildProductViewModels(from reportProducts: [PurchasesDiagnostics.ProductDiagnosticsPayload]) async -> [ProductViewModel] {
            let identifiers = Set(reportProducts.map(\.identifier))
            let storeProducts = await userViewModel.fetchStoreProducts(withIdentifiers: Array(identifiers))
                .reduce(into: [String: StoreProduct]()) { partialResult, storeProduct in
                    partialResult[storeProduct.productIdentifier] = storeProduct
                }

            return reportProducts.map { product in
                let storeProduct = storeProducts[product.identifier]
                return ProductViewModel(
                    id: product.identifier,
                    status: product.status,
                    title: product.title,
                    description: product.description,
                    purchasable: storeProduct,
                    isPurchased: {
                        guard let storeProduct else { return false }

                        return self.userViewModel.customerInfo?.allPurchasedProductIdentifiers.contains(storeProduct.productIdentifier) == true
                    },
                    purchase: {
                        guard let storeProduct else { return }

                        await self.userViewModel.purchase(storeProduct)
                    }
                )
            }
        }

        private func buildOfferingViewModels(from reportOfferings: [PurchasesDiagnostics.OfferingDiagnosticsPayload]) async -> [OfferingViewModel] {
            await userViewModel.fetchOfferings()

            let loadedOfferings = userViewModel.offerings?.all

            return reportOfferings.map { offering in
                let loadedOffering = loadedOfferings?[offering.identifier]

                return OfferingViewModel(
                    identifier: offering.identifier,
                    status: offering.status,
                    packages: offering.packages.map { package in
                        let loadedPackage = loadedOffering?.availablePackages.first(where: {
                            $0.storeProduct.productIdentifier == package.productIdentifier
                        })

                        return PackageViewModel(
                            id: package.identifier,
                            status: package.status,
                            title: package.productIdentifier,
                            description: package.description,
                            purchasable: loadedPackage,
                            isPurchased: {
                                guard let loadedPackage else { return false }

                                return self.userViewModel.customerInfo?.allPurchasedProductIdentifiers.contains(loadedPackage.storeProduct.productIdentifier) == true
                            },
                            purchase: {
                                guard let loadedPackage else { return }

                                await self.userViewModel.purchase(loadedPackage)
                            },
                        )
                    }
                )
            }
        }
    }
#endif
