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
    private let productsManager: ProductsManager

    init(deviceCache: DeviceCache,
         operationDispatcher: OperationDispatcher,
         systemInfo: SystemInfo,
         backend: Backend,
         offeringsFactory: OfferingsFactory,
         productsManager: ProductsManager) {
        self.deviceCache = deviceCache
        self.operationDispatcher = operationDispatcher
        self.systemInfo = systemInfo
        self.backend = backend
        self.offeringsFactory = offeringsFactory
        self.productsManager = productsManager
    }

    func offerings(appUserID: String, completion: ((Result<Offerings, Error>) -> Void)?) {
        guard let cachedOfferings = deviceCache.cachedOfferings else {
            Logger.debug(Strings.offering.no_cached_offerings_fetching_from_network)
            systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.updateOfferingsCache(appUserID: appUserID,
                                          isAppBackgrounded: isAppBackgrounded,
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
                                          completion: nil)

                Logger.rcSuccess(Strings.offering.offerings_stale_updated_from_network)
            }
        }
    }

    func updateOfferingsCache(
        appUserID: String,
        isAppBackgrounded: Bool,
        completion: ((Result<Offerings, Error>) -> Void)?
    ) {
        deviceCache.setOfferingsCacheTimestampToNow()
        operationDispatcher.dispatchOnWorkerThread(withRandomDelay: isAppBackgrounded) {
            self.backend.getOfferings(appUserID: appUserID) { result in
                switch result {
                case let .success(response):
                    self.handleOfferingsBackendResult(with: response, completion: completion)

                case let .failure(error):
                    self.handleOfferingsUpdateError(.backendError(error), completion: completion)
                }
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

}

private extension OfferingsManager {

    func handleOfferingsBackendResult(
        with response: OfferingsResponse,
        completion: ((Result<Offerings, Error>) -> Void)?
    ) {
        let productIdentifiers = response.productIdentifiers

        guard !productIdentifiers.isEmpty else {
            let errorMessage = Strings.offering.configuration_error_no_products_for_offering.description
            self.handleOfferingsUpdateError(.configurationError(errorMessage),
                                            completion: completion)
            return
        }

        productsManager.products(withIdentifiers: productIdentifiers) { result in
            let products = result.value ?? []

            guard products.isEmpty == false else {
                let errorMessage = Strings.offering.configuration_error_skproducts_not_found.description
                self.handleOfferingsUpdateError(.configurationError(errorMessage),
                                                completion: completion)
                return
            }

            let productsByID = products.dictionaryWithKeys { $0.productIdentifier }

            let missingProductIDs = self.getMissingProductIDs(productIDsFromStore: Set(productsByID.keys),
                                                              productIDsFromBackend: productIdentifiers)
            if !missingProductIDs.isEmpty {
                Logger.appleWarning(
                    Strings.offering.cannot_find_product_configuration_error(identifiers: missingProductIDs)
                )
            }

            if let createdOfferings = self.offeringsFactory.createOfferings(from: productsByID, data: response) {
                self.deviceCache.cache(offerings: createdOfferings)
                self.dispatchCompletionOnMainThreadIfPossible(completion, result: .success(createdOfferings))
            } else {
                self.handleOfferingsUpdateError(.noOfferingsFound(), completion: completion)
            }
        }
    }

    func handleOfferingsUpdateError(_ error: Error, completion: ((Result<Offerings, Error>) -> Void)?) {
        Logger.appleError(Strings.offering.fetching_offerings_error(error: error.localizedDescription))
        deviceCache.clearOfferingsCacheTimestamp()
        dispatchCompletionOnMainThreadIfPossible(completion, result: .failure(error))
    }

    func dispatchCompletionOnMainThreadIfPossible(_ completion: ((Result<Offerings, Error>) -> Void)?,
                                                  result: Result<Offerings, Error>) {
        if let completion = completion {
            operationDispatcher.dispatchOnMainThread {
                completion(result)
            }
        }
    }

}

extension OfferingsManager {

    enum Error: Swift.Error, Equatable {

        case backendError(BackendError)
        case configurationError(String, ErrorSource)
        case noOfferingsFound(ErrorSource)

    }

}

extension OfferingsManager.Error: ErrorCodeConvertible {

    var asPurchasesError: Error {
        switch self {
        case let .backendError(backendError):
            return backendError.asPurchasesError

        case let .configurationError(errorMessage, source):
            return ErrorUtils.configurationError(message: errorMessage,
                                                 fileName: source.file,
                                                 functionName: source.function,
                                                 line: source.line)

        case let .noOfferingsFound(source):
            return ErrorUtils.unexpectedBackendResponseError(fileName: source.file,
                                                             functionName: source.function,
                                                             line: source.line)
        }
    }

    static func configurationError(
        _ errorMessage: String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        return .configurationError(errorMessage, .init(file: file, function: function, line: line))
    }

    static func noOfferingsFound(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> Self {
        return .noOfferingsFound(.init(file: file, function: function, line: line))
    }

}
