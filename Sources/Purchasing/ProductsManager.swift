//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManager.swift
//
//  Created by Andrés Boedo on 7/14/20.
//

import Foundation
import StoreKit

// MARK: -

/// Basic implemenation of a `ProductsManagerType`
class ProductsManager: NSObject, ProductsManagerType {

    private let productsFetcherSK1: ProductsFetcherSK1
    private let diagnosticsTracker: DiagnosticsTrackerType?
    private let systemInfo: SystemInfo
    private let dateProvider: DateProvider

    private let _productsFetcherSK2: (any Sendable)?

    private let installmentsInfoFactory: InstallmentsInfoFactoryType

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private var productsFetcherSK2: ProductsFetcherSK2 {
        // swiftlint:disable:next force_cast force_unwrapping
        return self._productsFetcherSK2! as! ProductsFetcherSK2
    }

    init(
        productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
        diagnosticsTracker: DiagnosticsTrackerType?,
        systemInfo: SystemInfo,
        requestTimeout: TimeInterval,
        installmentsInfoFactory: InstallmentsInfoFactoryType = InstallmentsInfoFactory(),
        dateProvider: DateProvider = DateProvider()
    ) {
        self.productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                     requestTimeout: requestTimeout)
        self.diagnosticsTracker = diagnosticsTracker
        self.systemInfo = systemInfo
        self.dateProvider = dateProvider
        self.installmentsInfoFactory = installmentsInfoFactory

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            self._productsFetcherSK2 = ProductsFetcherSK2()
        } else {
            self._productsFetcherSK2 = nil
        }
    }

    // swiftlint:disable:next function_body_length
    func products(withIdentifiers identifiers: Set<String>, completion: @escaping Completion) {
        let startTime = self.dateProvider.now()

        // It's possible for developers to request compound product identifiers that represent both
        // a product and a billing plan, like com.rc.sub:monthly. However, StoreKit doesn't recognize
        // these product IDs, so here, we convert them to product IDs that StoreKit can recognize.
        var invalidProductIdentifiers: Set<String> = []
        let compoundProductIdentifiers: Set<CompoundProductIdentifier> = Set(
            identifiers.compactMap { identifier in
                guard let compoundIdentifier = CompoundProductIdentifier(compoundProductIdentifier: identifier) else {
                    invalidProductIdentifiers.insert(identifier)
                    return nil
                }

                // Don't return products with billing plans if running on <iOS 26.4, where they aren't supported
                if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
                    return compoundIdentifier
                } else {
                    guard compoundIdentifier.productPlanIdentifier == nil else {
                        Logger.warn(
                            StoreKitStrings.sk2_billing_plans_are_unavailable_on_this_os_version(
                                compoundProductIdentifier: compoundIdentifier
                            )
                        )
                        return nil
                    }

                    return compoundIdentifier
                }
            }
        )
        if !invalidProductIdentifiers.isEmpty {
            Logger.warn(Strings.storeKit.invalid_product_identifiers(identifiers: invalidProductIdentifiers))
        }

        let storeKitIdentifiers: Set<String> = Set(
            compoundProductIdentifiers.map(\.storeKitProductIdentifier)
        )

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.storeKitVersion.isStoreKit2EnabledAndAvailable {
            self.sk2Products(withIdentifiers: storeKitIdentifiers) { result in
                let notFoundProducts = storeKitIdentifiers.subtracting(result.value?.map(\.productIdentifier) ?? [])
                self.trackProductsRequestIfNeeded(startTime,
                                                  requestedProductIds: storeKitIdentifiers,
                                                  notFoundProductIds: notFoundProducts,
                                                  storeKitVersion: .storeKit2,
                                                  error: result.error)

                switch result {
                case .success(let storeProductsFromStoreKit):
                    let productsTakingBillingPlansIntoAccount = self.populateSK2CompoundProductsIfSupported(
                        requestedIdentifiers: compoundProductIdentifiers,
                        products: storeProductsFromStoreKit
                    )
                    let storeProducts = Set(productsTakingBillingPlansIntoAccount.map(StoreProduct.from(product:)))
                    completion(.success(storeProducts))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            self.sk1Products(withIdentifiers: storeKitIdentifiers) { result in
                let notFoundProducts = storeKitIdentifiers.subtracting(result.value?.map(\.productIdentifier) ?? [])
                self.trackProductsRequestIfNeeded(startTime,
                                                  requestedProductIds: storeKitIdentifiers,
                                                  notFoundProductIds: notFoundProducts,
                                                  storeKitVersion: .storeKit1,
                                                  error: result.error)
                completion(result.map { Set($0.map(StoreProduct.from(product:))) })
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>, completion: @escaping SK2Completion) {
        Async.call(with: completion) {
            do {
                let products = try await self.productsFetcherSK2.products(identifiers: identifiers)

                Logger.debug(Strings.storeKit.store_product_request_finished)
                return Set(products)
            } catch let error as NSError {
                Logger.debug(Strings.storeKit.store_products_request_failed(error))
                throw ErrorUtils.storeProblemError(error: error)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    // swiftlint:disable:next function_body_length
    func populateSK2CompoundProductsIfSupported(
        requestedIdentifiers: Set<CompoundProductIdentifier>,
        products: Set<SK2StoreProduct>
    ) -> Set<SK2StoreProduct> {
        // Billing plans were introduced with Xcode 26.5, which shipped with Swift version 6.3.2.
        #if compiler(>=6.3.2)
        if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
            let requestedIdentifiersWithPlanIdentifiers = requestedIdentifiers.filter {
                $0.productPlanIdentifier != nil
            }
            guard !requestedIdentifiersWithPlanIdentifiers.isEmpty else {
                return products
            }

            let productsByStoreKitProductIdentifier = products.dictionaryWithKeys({ $0.productIdentifier })
            var productsIncludingBillingPlanProducts = products

            // When the user requests a compound product ID but not the base product ID,
            // we only want to return the compound product
            func removeBaseProductIfNotRequested(_ product: SK2StoreProduct) {
                guard Self.shouldRemoveBaseSK2Product(
                    productIdentifier: product.productIdentifier,
                    requestedIdentifiers: requestedIdentifiers
                ) else {
                    return
                }

                productsIncludingBillingPlanProducts.remove(product)
            }

            for compoundProductIdentifier in requestedIdentifiersWithPlanIdentifiers {
                let storeKitProductIdentifier = compoundProductIdentifier.storeKitProductIdentifier
                guard let productFromStoreKit = productsByStoreKitProductIdentifier[storeKitProductIdentifier] else {
                    continue
                }

                guard let requestedBillingPlanType = compoundProductIdentifier.sk2BillingPlanType else {
                    // Unrecognized billing plan type. Return no products for this request.
                    Logger.warn(
                        StoreKitStrings.sk2_no_billing_plan_found(compoundProductIdentifier: compoundProductIdentifier)
                    )
                    removeBaseProductIfNotRequested(productFromStoreKit)
                    continue
                }
                guard let pricingTerms = productFromStoreKit.underlyingSK2Product.subscription?.pricingTerms else {
                    Logger.warn(
                        StoreKitStrings.sk2_no_pricing_terms_found(compoundProductIdentifier: compoundProductIdentifier)
                    )
                    removeBaseProductIfNotRequested(productFromStoreKit)
                    continue
                }

                if let requestedPricingTerms = pricingTerms.first(
                    where: { $0.billingPlanType == requestedBillingPlanType }
                ) {
                    let installmentsInfo: InstallmentsInfo? = installmentsInfoFactory.buildInstallmentsInfo(
                        from: productFromStoreKit.underlyingSK2Product,
                        billingPlanType: requestedBillingPlanType,
                        pricingTerms: requestedPricingTerms
                    )

                    let billingPlanProduct = SK2StoreProduct(
                        sk2Product: productFromStoreKit.underlyingSK2Product,
                        compoundProductIdentifier: compoundProductIdentifier,
                        installmentsInfo: installmentsInfo
                    )
                    productsIncludingBillingPlanProducts.insert(billingPlanProduct)
                    removeBaseProductIfNotRequested(productFromStoreKit)
                } else {
                    // The requested billing plan isn't available for this user. Return no products for this request.
                    Logger.warn(
                        StoreKitStrings.sk2_user_not_eligible_for_billing_plan(
                            compoundProductIdentifier: compoundProductIdentifier
                        )
                    )
                    removeBaseProductIfNotRequested(productFromStoreKit)
                }
            }

            return productsIncludingBillingPlanProducts
        } else {
            return products
        }

        #else
        // Billing plans aren't supported
        return products
        #endif
    }

    static func shouldRemoveBaseSK2Product(
        productIdentifier: String,
        requestedIdentifiers: Set<CompoundProductIdentifier>
    ) -> Bool {
        return !requestedIdentifiers.contains {
            $0.productPlanIdentifier == nil
                && $0.storeKitProductIdentifier == productIdentifier
        }
    }

    // This class does not implement caching.
    // See `CachingProductsManager`.
    func cache(_ product: StoreProductType) {}
    func clearCache() {
        self.productsFetcherSK1.clearCache()
    }

    var requestTimeout: TimeInterval {
        return self.productsFetcherSK1.requestTimeout
    }

}

// MARK: - private

private extension ProductsManager {

    func sk1Products(withIdentifiers identifiers: Set<String>,
                     completion: @escaping (Result<Set<SK1StoreProduct>, PurchasesError>) -> Void) {
        return self.productsFetcherSK1.products(withIdentifiers: identifiers, completion: completion)
    }

    func trackProductsRequestIfNeeded(_ startTime: Date,
                                      requestedProductIds: Set<String>,
                                      notFoundProductIds: Set<String>,
                                      storeKitVersion: StoreKitVersion,
                                      error: PurchasesError?) {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *),
           let diagnosticsTracker = self.diagnosticsTracker {
            let responseTime = self.dateProvider.now().timeIntervalSince(startTime)
            let errorMessage = (error?.userInfo[NSUnderlyingErrorKey] as? Error)?.localizedDescription
                ?? error?.localizedDescription
            let errorCode = error?.errorCode
            let storeKitErrorDescription = StoreKitErrorUtils.extractStoreKitErrorDescription(from: error)
            diagnosticsTracker.trackProductsRequest(wasSuccessful: error == nil,
                                                    storeKitVersion: storeKitVersion,
                                                    errorMessage: errorMessage,
                                                    errorCode: errorCode,
                                                    storeKitErrorDescription: storeKitErrorDescription,
                                                    storefront: self.systemInfo.storefront?.countryCode,
                                                    requestedProductIds: requestedProductIds,
                                                    notFoundProductIds: notFoundProductIds,
                                                    responseTime: responseTime)
        }
    }

}

// MARK: - ProductsManagerType async

extension ProductsManagerType {

    /// `async` overload for `products(withIdentifiers:)`
    func products(withIdentifiers identifiers: Set<String>) async throws -> Set<StoreProduct> {
        return try await Async.call { completion in
            self.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    /// `async` overload for `sk2Products(withIdentifiers:)`
    ///
    /// - Throws: `PurchasesError`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(withIdentifiers identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        return try await Async.call { completion in
            self.sk2Products(withIdentifiers: identifiers, completion: completion)
        }
    }

}

// MARK: -

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
// However it contains no mutable state, and its members are all `Sendable`.
extension ProductsManager: @unchecked Sendable {}
