//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsManager.swift
//
//  Created by Juanpe Catalán on 8/8/21.

import Foundation
import StoreKit

// swiftlint:disable file_length

class OfferingsManager {

    private let deviceCache: DeviceCache
    private let operationDispatcher: OperationDispatcher
    private let systemInfo: SystemInfo
    private let backend: Backend
    private let offeringsFactory: OfferingsFactory
    private let productsManager: ProductsManagerType

    init(deviceCache: DeviceCache,
         operationDispatcher: OperationDispatcher,
         systemInfo: SystemInfo,
         backend: Backend,
         offeringsFactory: OfferingsFactory,
         productsManager: ProductsManagerType) {
        self.deviceCache = deviceCache
        self.operationDispatcher = operationDispatcher
        self.systemInfo = systemInfo
        self.backend = backend
        self.offeringsFactory = offeringsFactory
        self.productsManager = productsManager
    }

    func offerings(
        appUserID: String,
        fetchPolicy: FetchPolicy = .default,
        fetchCurrent: Bool = false,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        guard !fetchCurrent else {
            self.fetchFromNetwork(appUserID: appUserID, fetchPolicy: fetchPolicy, completion: completion)
            return
        }

        guard let memoryCachedOfferings = self.cachedOfferings else {
            self.fetchFromNetwork(appUserID: appUserID, fetchPolicy: fetchPolicy, completion: completion)
            return
        }

        Logger.debug(Strings.offering.vending_offerings_cache_from_memory)
        self.dispatchCompletionOnMainThreadIfPossible(completion, value: .success(memoryCachedOfferings))

        self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            if self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded) {
                self.updateOfferingsCache(appUserID: appUserID,
                                          isAppBackgrounded: isAppBackgrounded,
                                          fetchPolicy: fetchPolicy,
                                          completion: nil)
            }
        }
    }

    var cachedOfferings: Offerings? {
        return self.deviceCache.cachedOfferings
    }

    func updateOfferingsCache(
        appUserID: String,
        isAppBackgrounded: Bool,
        fetchPolicy: FetchPolicy = .default,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        self.backend.offerings.getOfferings(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded) { result in
            switch result {
            case let .success(response):
                self.handleOfferingsBackendResult(with: response,
                                                  appUserID: appUserID,
                                                  fetchPolicy: fetchPolicy,
                                                  completion: completion)

            case let .failure(.networkError(networkError)) where networkError.isServerDown:
                Logger.warn(Strings.offering.fetching_offerings_failed_server_down)

                // If unable to fetch offerings when server is down, attempt to load them from disk cache.
                self.fetchCachedOfferingsFromDisk(appUserID: appUserID,
                                                  fetchPolicy: fetchPolicy) { offerings in
                    if let offerings = offerings {
                        self.dispatchCompletionOnMainThreadIfPossible(completion, value: .success(offerings))
                    } else {
                        self.handleOfferingsUpdateError(.backendError(.networkError(networkError)),
                                                        completion: completion)
                    }
                }

            case let .failure(error):
                self.handleOfferingsUpdateError(.backendError(error), completion: completion)
            }
        }
    }

    func getMissingProductIDs(productIDsFromStore: Set<String>,
                              productIDsFromBackend: Set<String>) -> Set<String> {
        guard !productIDsFromBackend.isEmpty else {
            return []
        }

        return productIDsFromBackend.subtracting(productIDsFromStore)
    }

    func invalidateCachedOfferings(appUserID: String) {
        self.deviceCache.clearOfferingsCache(appUserID: appUserID)
    }

    func invalidateAndReFetchCachedOfferingsIfAppropiate(appUserID: String) {
        let cachedOfferings = self.deviceCache.cachedOfferings
        self.invalidateCachedOfferings(appUserID: appUserID)

        if cachedOfferings != nil {
            self.offerings(appUserID: appUserID, fetchPolicy: .ignoreNotFoundProducts) { @Sendable _ in }
        }
    }

}

private extension OfferingsManager {

    func fetchFromNetwork(
        appUserID: String,
        fetchPolicy: FetchPolicy = .default,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        Logger.debug(Strings.offering.no_cached_offerings_fetching_from_network)

        self.systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            self.updateOfferingsCache(appUserID: appUserID,
                                      isAppBackgrounded: isAppBackgrounded,
                                      fetchPolicy: fetchPolicy,
                                      completion: completion)
        }
    }

    func fetchCachedOfferingsFromDisk(
        appUserID: String,
        fetchPolicy: FetchPolicy,
        completion: (@escaping @Sendable (Offerings?) -> Void)
    ) {
        guard let data = self.deviceCache.cachedOfferingsResponseData(appUserID: appUserID),
              let response: OfferingsResponse = try? JSONDecoder.default.decode(jsonData: data, logErrors: true) else {
            completion(nil)
            return
        }

        self.createOfferings(
            from: response,
            fetchPolicy: fetchPolicy,
            completion: { [cache = self.deviceCache] result in
                switch result {
                case let .success(offerings):
                    Logger.debug(Strings.offering.vending_offerings_cache_from_disk)

                    // Cache in memory but as stale, so it can be re-updated when possible
                    cache.cacheInMemory(offerings: offerings)
                    cache.clearOfferingsCacheTimestamp()

                    completion(offerings)

                case .failure:
                    completion(nil)
                }
            }
        )
    }

    func createOfferings(
        from response: OfferingsResponse,
        fetchPolicy: FetchPolicy,
        completion: @escaping (@Sendable (Result<Offerings, Error>) -> Void)
    ) {
        let productIdentifiers = response.productIdentifiers

        guard !productIdentifiers.isEmpty else {
            let errorMessage = Strings.offering.configuration_error_no_products_for_offering.description
            completion(.failure(.configurationError(errorMessage, underlyingError: nil)))
            return
        }

        self.fetchProducts(withIdentifiers: productIdentifiers, fromResponse: response) { result in
            let products = result.value ?? []

            guard products.isEmpty == false else {
                completion(.failure(Self.createErrorForEmptyResult(result.error)))
                return
            }

            let productsByID = products.dictionaryWithKeys { $0.productIdentifier }

            let missingProductIDs = self.getMissingProductIDs(productIDsFromStore: Set(productsByID.keys),
                                                              productIDsFromBackend: productIdentifiers)
            if !missingProductIDs.isEmpty {
                switch fetchPolicy {
                case .ignoreNotFoundProducts:
                    Logger.appleWarning(
                        Strings.offering.cannot_find_product_configuration_error(identifiers: missingProductIDs)
                    )

                case .failIfProductsAreMissing:
                    completion(.failure(.missingProducts(identifiers: missingProductIDs)))
                    return
                }
            }

            if let createdOfferings = self.offeringsFactory.createOfferings(from: productsByID, data: response) {
                completion(.success(createdOfferings))
            } else {
                completion(.failure(.noOfferingsFound()))
            }
        }
    }

    func handleOfferingsBackendResult(
        with response: OfferingsResponse,
        appUserID: String,
        fetchPolicy: FetchPolicy,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        self.createOfferings(from: response, fetchPolicy: fetchPolicy) { result in
            switch result {
            case let .success(offerings):
                Logger.rcSuccess(Strings.offering.offerings_stale_updated_from_network)

                self.deviceCache.cache(offerings: offerings, appUserID: appUserID)
                self.dispatchCompletionOnMainThreadIfPossible(completion, value: .success(offerings))

            case let .failure(error):
                self.handleOfferingsUpdateError(error, completion: completion)
            }
        }
    }

    private static func createErrorForEmptyResult(_ error: PurchasesError?) -> OfferingsManager.Error {
        if let purchasesError = error,
           case ErrorCode.productRequestTimedOut = purchasesError.error {
            return .timeout(purchasesError)
        } else {
            return .configurationError(Strings.offering.configuration_error_products_not_found.description,
                                       underlyingError: error?.asPublicError)
        }
    }

    func handleOfferingsUpdateError(
        _ error: Error,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        Logger.appleError(Strings.offering.fetching_offerings_error(error: error,
                                                                    underlyingError: error.underlyingError))
        self.dispatchCompletionOnMainThreadIfPossible(completion, value: .failure(error))
    }

    func dispatchCompletionOnMainThreadIfPossible<T>(
        _ completion: (@MainActor @Sendable (T) -> Void)?,
        value: T
    ) {
        if let completion = completion {
            self.operationDispatcher.dispatchOnMainActor {
                completion(value)
            }
        }
    }

    private func fetchProducts(
        withIdentifiers identifiers: Set<String>,
        fromResponse response: OfferingsResponse,
        completion: @escaping ProductsManagerType.Completion
    ) {
        if self.systemInfo.dangerousSettings.uiPreviewMode {
            let mockProducts = self.createMockProducts(productIdentifiers: identifiers, fromResponse: response)
            completion(.success(mockProducts))
        } else {
            self.productsManager.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    // MARK: - Mocks for UI Preview mode

    private func createMockProducts(
        productIdentifiers: Set<String>,
        fromResponse response: OfferingsResponse
    ) -> Set<StoreProduct> {
        let packagesByProductID = response.packages.dictionaryAllowingDuplicateKeys { $0.platformProductIdentifier }
        let products = productIdentifiers.map { identifier -> StoreProduct in
            let productType = self.mockProductType(from: packagesByProductID[identifier],
                                                   productIdentifier: identifier)

            let introductoryDiscount: TestStoreProductDiscount? = {
                // For mocking purposes: all yearly subscriptions have a 1-week free trial
                guard productType.period?.unit == .year else { return nil }
                return TestStoreProductDiscount(
                    identifier: "intro",
                    price: 0,
                    localizedPriceString: "$0.00",
                    paymentMode: .freeTrial,
                    subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .week),
                    numberOfPeriods: 1,
                    type: .introductory
                )
            }()

            let testProduct = TestStoreProduct(
                localizedTitle: "PRO \(productType.type)",
                price: Decimal(productType.price),
                localizedPriceString: String(format: "$%.2f", productType.price),
                productIdentifier: identifier,
                productType: productType.period == nil ? .nonConsumable : .autoRenewableSubscription,
                localizedDescription: "\(productType.type) subscription",
                subscriptionGroupIdentifier: productType.period == nil ? nil : "group",
                subscriptionPeriod: productType.period,
                introductoryDiscount: introductoryDiscount,
                discounts: []
            )

            return testProduct.toStoreProduct()
        }

        return Set(products)
    }

    private func mockProductType(
        from package: OfferingsResponse.Offering.Package?,
        productIdentifier: String
    ) -> ProductTypeMock {
        if let package,
           let mockProductType = ProductTypeMock(packageType: Package.packageType(from: package.identifier)) {
            return mockProductType
        } else {
            // Try to guess basing on the product identifier
            let id = productIdentifier.lowercased()

            let packageType: PackageType
            if id.contains("lifetime") || id.contains("forever") || id.contains("permanent") {
                packageType = .lifetime
            } else if id.contains("annual") || id.contains("year") {
                packageType = .annual
            } else if id.contains("sixmonth") || id.contains("6month") {
                packageType = .sixMonth
            } else if id.contains("threemonth") || id.contains("3month") || id.contains("quarter") {
                packageType = .threeMonth
            } else if id.contains("twomonth") || id.contains("2month") {
                packageType = .twoMonth
            } else if id.contains("month") {
                packageType = .monthly
            } else if id.contains("week") {
                packageType = .weekly
            } else {
                packageType = .custom
            }
            return ProductTypeMock(packageType: packageType) ?? .default
        }
    }
}

extension OfferingsManager {

    /// Determines the behavior when products in an `Offering` are not found
    internal enum FetchPolicy {

        case ignoreNotFoundProducts
        case failIfProductsAreMissing

        static let `default`: Self = .ignoreNotFoundProducts

    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension OfferingsManager: @unchecked Sendable {}

// MARK: - Errors

extension OfferingsManager {

    enum Error: Swift.Error {

        case backendError(BackendError)
        case configurationError(String, PublicError?, ErrorSource)
        case timeout(PurchasesError)
        case noOfferingsFound(ErrorSource)
        case missingProducts(identifiers: Set<String>, ErrorSource)

    }

}

extension OfferingsManager.Error: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
        switch self {
        case let .backendError(backendError):
            return backendError.asPurchasesError

        case let .timeout(underlyingError):
            return underlyingError

        case let .configurationError(errorMessage, underlyingError, source):
            return ErrorUtils.configurationError(message: errorMessage,
                                                 underlyingError: underlyingError,
                                                 fileName: source.file,
                                                 functionName: source.function,
                                                 line: source.line)

        case let .noOfferingsFound(source):
            return ErrorUtils.unexpectedBackendResponseError(fileName: source.file,
                                                             functionName: source.function,
                                                             line: source.line)

        case let .missingProducts(identifiers, source):
            return ErrorUtils.configurationError(
                message: Strings.offering.cannot_find_product_configuration_error(identifiers: identifiers).description,
                fileName: source.file,
                functionName: source.function,
                line: source.line
            )
        }
    }

    static func configurationError(
        _ errorMessage: String,
        underlyingError: NSError?,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        return .configurationError(errorMessage, underlyingError, .init(file: file, function: function, line: line))
    }

    static func noOfferingsFound(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        return .noOfferingsFound(.init(file: file, function: function, line: line))
    }

    static func missingProducts(
        identifiers: Set<String>,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        return .missingProducts(identifiers: identifiers, .init(file: file, function: function, line: line))
    }

}

extension OfferingsManager.Error: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSUnderlyingErrorKey: self.underlyingError as NSError? as Any
        ]
    }

    var errorDescription: String? {
        switch self {
        case .backendError: return nil
        case let .timeout(underlyingError): return underlyingError.error.localizedDescription
        case let .configurationError(message, _, _): return message
        case .noOfferingsFound: return nil
        case .missingProducts: return nil
        }
    }

    fileprivate var underlyingError: Error? {
        switch self {
        case let .backendError(.networkError(error)): return error
        case let .backendError(error): return error
        case let .timeout(underlyingError): return underlyingError
        case let .configurationError(_, error, _): return error
        case .noOfferingsFound: return nil
        case .missingProducts: return nil
        }
    }

}

/// For UI Preview mode only.
private struct ProductTypeMock {
    let type: String
    let price: Double
    let period: SubscriptionPeriod?

    static let `default` = ProductTypeMock(type: "lifetime", price: 249.99, period: nil)

    private init(type: String, price: Double, period: SubscriptionPeriod?) {
        self.type = type
        self.price = price
        self.period = period
    }

    init?(packageType: PackageType) {
        switch packageType {
        case .lifetime:
            self = ProductTypeMock(type: "lifetime",
                                   price: 199.99,
                                   period: nil)
        case .annual:
            self = ProductTypeMock(type: "yearly",
                                   price: 59.99,
                                   period: SubscriptionPeriod(value: 1, unit: .year))
        case .sixMonth:
            self = ProductTypeMock(type: "6 months",
                                   price: 30.99,
                                   period: SubscriptionPeriod(value: 3, unit: .month))
        case .threeMonth:
            self = ProductTypeMock(type: "3 months",
                                   price: 15.99,
                                   period: SubscriptionPeriod(value: 3, unit: .month))
        case .twoMonth:
            self = ProductTypeMock(type: "monthly",
                                   price: 11.49,
                                   period: SubscriptionPeriod(value: 2, unit: .month))
        case .monthly:
            self = ProductTypeMock(type: "monthly",
                                   price: 5.99,
                                   period: SubscriptionPeriod(value: 1, unit: .month))
        case .weekly:
            self = ProductTypeMock(type: "weekly",
                                   price: 1.99,
                                   period: SubscriptionPeriod(value: 1, unit: .week))
        case .unknown, .custom:
            return nil
        }
    }
}
