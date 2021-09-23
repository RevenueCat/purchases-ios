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
            self.backend.getOfferings(appUserID: appUserID) { maybeData, maybeError in
                if let data = maybeData {
                    self.handleOfferingsBackendResult(with: data, completion: completion)
                } else if let error = maybeError {
                    self.handleOfferingsUpdateError(error, completion: completion)
                }
            }
        }
    }

}

private extension OfferingsManager {

    func handleOfferingsBackendResult(with data: [String: Any], completion: ((Offerings?, Error?) -> Void)?) {
        let productIdentifiers = extractProductIdentifiers(fromOfferingsData: data)

        productsManager.products(withIdentifiers: productIdentifiers) { products in
            let productsByID = products.reduce(into: [:]) { result, product in
                result[product.productIdentifier] = product
            }

            self.logMissingProductsIfAppropriate(products: productsByID,
                                                 productIdentifiers: productIdentifiers)

            if let createdOfferings = self.offeringsFactory.createOfferings(withProducts: productsByID, data: data) {
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
        guard let offerings = offeringsData["offerings"] as? [[String: Any]] else {
            return []
        }

        let productIdenfitiersArray = offerings
            .compactMap { $0["packages"] as? [[String: Any]] }
            .flatMap { $0 }
            .compactMap { $0["platform_product_identifier"] as? String }

        return Set(productIdenfitiersArray)
    }

    func logMissingProductsIfAppropriate(products: [String: SKProduct],
                                         productIdentifiers: Set<String>) {
        guard !productIdentifiers.isEmpty else {
            return
        }

        let missingProductIdentifiers = productIdentifiers.subtracting(Set(products.keys))

        if !missingProductIdentifiers.isEmpty {
            Logger.appleWarning(
                Strings.offering.cannot_find_product_configuration_error(identifiers: missingProductIdentifiers))
        }
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
