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

    func offerings(appUserID: String, completion: ((Offerings?, Error?) -> Void)?) {
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
        dispatchCompletionOnMainThreadIfPossible(completion,
                                                 offerings: cachedOfferings,
                                                 error: nil)

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

    func updateOfferingsCache(appUserID: String, isAppBackgrounded: Bool, completion: ((Offerings?, Error?) -> Void)?) {
        deviceCache.setOfferingsCacheTimestampToNow()
        operationDispatcher.dispatchOnWorkerThread(withRandomDelay: isAppBackgrounded) {
            self.backend.getOfferings(appUserID: appUserID) { result in
                switch result {
                case let .success(data):
                    self.handleOfferingsBackendResult(with: data, completion: completion)

                case let .failure(error):
                    self.handleOfferingsUpdateError(error, completion: completion)
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

    func handleOfferingsBackendResult(with data: [String: Any], completion: ((Offerings?, Error?) -> Void)?) {
        let productIdentifiers = extractProductIdentifiers(fromOfferingsData: data)
        guard !productIdentifiers.isEmpty else {
            let errorMessage = Strings.offering.configuration_error_no_products_for_offering.description
            self.handleOfferingsUpdateError(ErrorUtils.configurationError(message: errorMessage),
                                            completion: completion)
            return
        }

        productsManager.products(withIdentifiers: productIdentifiers) { result in
            let products = result.value ?? []

            guard products.isEmpty == false else {
                let errorMessage = Strings.offering.configuration_error_skproducts_not_found.description
                self.handleOfferingsUpdateError(ErrorUtils.configurationError(message: errorMessage),
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

            if let createdOfferings = self.offeringsFactory.createOfferings(from: productsByID,
                                                                            data: data) {
                self.deviceCache.cache(offerings: createdOfferings)
                self.dispatchCompletionOnMainThreadIfPossible(completion,
                                                              offerings: createdOfferings,
                                                              error: nil)
            } else {
                self.handleOfferingsUpdateError(ErrorUtils.unexpectedBackendResponseError(), completion: completion)
            }
        }
    }

    func handleOfferingsUpdateError(_ error: Error, completion: ((Offerings?, Error?) -> Void)?) {
        Logger.appleError(Strings.offering.fetching_offerings_error(error: error.localizedDescription))
        deviceCache.clearOfferingsCacheTimestamp()
        dispatchCompletionOnMainThreadIfPossible(completion,
                                                 offerings: nil,
                                                 error: error)
    }

    func extractProductIdentifiers(fromOfferingsData offeringsData: [String: Any]) -> Set<String> {
        // Fixme: parse Data directly instead of converting from Data to Dictionary back to Data
        guard let data = try? JSONSerialization.data(withJSONObject: offeringsData),
              let response: OfferingsResponse = try? JSONDecoder.default.decode(jsonData: data) else {
            return []
        }

        return Set(response.productIdentifiers)
    }

    func dispatchCompletionOnMainThreadIfPossible(_ completion: ((Offerings?, Error?) -> Void)?,
                                                  offerings: Offerings?,
                                                  error: Error?) {
        if let completion = completion {
            operationDispatcher.dispatchOnMainThread {
                completion(offerings, error)
            }
        }
    }

}

// swiftlint:disable nesting

private struct OfferingsResponse {

    struct Offering {

        struct Package {

            let identifier: String
            let platformProductIdentifier: String

        }

        let description: String
        let identifier: String
        let packages: [Package]

    }

    let currentOfferingId: String
    let offerings: [Offering]

}

extension OfferingsResponse {

    var productIdentifiers: [String] {
        return self.offerings
            .lazy
            .flatMap { $0.packages }
            .map { $0.platformProductIdentifier }
    }

}

extension OfferingsResponse.Offering.Package: Decodable {}
extension OfferingsResponse.Offering: Decodable {}
extension OfferingsResponse: Decodable {}
