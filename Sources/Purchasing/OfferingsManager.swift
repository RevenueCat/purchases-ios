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
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        guard let cachedOfferings = self.deviceCache.cachedOfferings else {
            Logger.debug(Strings.offering.no_cached_offerings_fetching_from_network)
            systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.updateOfferingsCache(appUserID: appUserID,
                                          isAppBackgrounded: isAppBackgrounded,
                                          fetchPolicy: fetchPolicy,
                                          completion: completion)
            }
            return
        }

        Logger.debug(Strings.offering.vending_offerings_cache)
        dispatchCompletionOnMainThreadIfPossible(completion, result: .success(cachedOfferings))

        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            if self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded) {
                Logger.debug(isAppBackgrounded
                             ? Strings.offering.offerings_stale_updating_in_background
                             : Strings.offering.offerings_stale_updating_in_foreground)

                self.updateOfferingsCache(appUserID: appUserID,
                                          isAppBackgrounded: isAppBackgrounded,
                                          fetchPolicy: fetchPolicy,
                                          completion: nil)

                Logger.rcSuccess(Strings.offering.offerings_stale_updated_from_network)
            }
        }
    }

    func updateOfferingsCache(
        appUserID: String,
        isAppBackgrounded: Bool,
        fetchPolicy: FetchPolicy = .default,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        self.backend.offerings.getOfferings(appUserID: appUserID, withRandomDelay: isAppBackgrounded) { result in
            switch result {
            case let .success(response):
                self.handleOfferingsBackendResult(with: response,
                                                  fetchPolicy: fetchPolicy,
                                                  completion: completion)

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

    func invalidateAndReFetchCachedOfferingsIfAppropiate(appUserID: String) {
        let cachedOfferings = self.deviceCache.cachedOfferings
        self.deviceCache.clearCachedOfferings()

        if cachedOfferings != nil {
            self.offerings(appUserID: appUserID, fetchPolicy: .ignoreNotFoundProducts) { @Sendable _ in }
        }
    }

}

private extension OfferingsManager {

    func handleOfferingsBackendResult(
        with response: OfferingsResponse,
        fetchPolicy: FetchPolicy,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        let productIdentifiers = response.productIdentifiers

        guard !productIdentifiers.isEmpty else {
            let errorMessage = Strings.offering.configuration_error_no_products_for_offering.description
            self.handleOfferingsUpdateError(.configurationError(errorMessage, underlyingError: nil),
                                            completion: completion)
            return
        }

        self.productsManager.products(withIdentifiers: productIdentifiers) { result in
            let products = result.value ?? []

            guard products.isEmpty == false else {
                self.handleOfferingsUpdateError(
                    .configurationError(Strings.offering.configuration_error_products_not_found.description,
                                        underlyingError: result.error as NSError?),
                    completion: completion
                )
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
                    self.handleOfferingsUpdateError(
                        .missingProducts(identifiers: missingProductIDs),
                        completion: completion
                    )
                    return
                }
            }

            if let createdOfferings = self.offeringsFactory.createOfferings(from: productsByID, data: response) {
                self.deviceCache.cache(offerings: createdOfferings)
                self.dispatchCompletionOnMainThreadIfPossible(completion, result: .success(createdOfferings))
            } else {
                self.handleOfferingsUpdateError(.noOfferingsFound(), completion: completion)
            }
        }
    }

    func handleOfferingsUpdateError(
        _ error: Error,
        completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?
    ) {
        Logger.appleError(Strings.offering.fetching_offerings_error(error: error,
                                                                    underlyingError: error.underlyingError))
        self.deviceCache.clearOfferingsCacheTimestamp()
        self.dispatchCompletionOnMainThreadIfPossible(completion, result: .failure(error))
    }

    func dispatchCompletionOnMainThreadIfPossible(
        _ completion: (@MainActor @Sendable (Result<Offerings, Error>) -> Void)?,
        result: Result<Offerings, Error>
    ) {
        if let completion = completion {
            self.operationDispatcher.dispatchOnMainActor {
                completion(result)
            }
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

    enum Error: Swift.Error, Equatable {

        case backendError(BackendError)
        case configurationError(String, NSError?, ErrorSource)
        case noOfferingsFound(ErrorSource)
        case missingProducts(identifiers: Set<String>, ErrorSource)

    }

}

extension OfferingsManager.Error: PurchasesErrorConvertible {

    var asPurchasesError: PurchasesError {
        switch self {
        case let .backendError(backendError):
            return backendError.asPurchasesError

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
        case let .configurationError(message, _, _): return message
        case .noOfferingsFound: return nil
        case .missingProducts: return nil
        }
    }

    fileprivate var underlyingError: Error? {
        switch self {
        case let .backendError(.networkError(error)): return error
        case let .backendError(error): return error
        case let .configurationError(_, error, _): return error
        case .noOfferingsFound: return nil
        case .missingProducts: return nil
        }
    }

}
