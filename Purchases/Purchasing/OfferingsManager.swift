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
                    return
                }

                let error = maybeError ?? ErrorUtils.unexpectedBackendResponseError()
                self.handleOfferingsUpdateError(error, completion: completion)
            }
        }
    }

    func getMissingProductIDs(productsFromStore: [String: SKProduct],
                              productIDsFromBackend: Set<String>) -> Set<String> {
        guard !productIDsFromBackend.isEmpty else {
            return []
        }

        return productIDsFromBackend.subtracting(productsFromStore.keys)
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

        productsManager.productsFromOptimalStoreKitVersion(withIdentifiers: productIdentifiers) { result in
            let products = result.value ?? []

            guard products.isEmpty == false else {
                let errorMessage = Strings.offering.configuration_error_skproducts_not_found.description
                self.handleOfferingsUpdateError(ErrorUtils.configurationError(message: errorMessage),
                                                completion: completion)
                return
            }

            let productsByID = products.reduce(into: [:]) { result, product in
                result[product.productIdentifier] = product
            }

            if let createdOfferings = self.offeringsFactory.createOfferings(from: productsByID,
                                                                            data: data) {
                self.logMissingProductsIfAppropriate(products: productsByID, offeringsData: data)
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

    func logMissingProductsIfAppropriate(products: [String: StoreProduct], offeringsData: [String: Any]) {
        guard !products.isEmpty,
              !offeringsData.isEmpty else {
                  return
              }

        let productIdentifiers = extractProductIdentifiers(fromOfferingsData: offeringsData)
        let missingProducts = Set(products.keys).intersection(productIdentifiers)

        if !missingProducts.isEmpty {
            Logger.appleWarning(Strings.offering.cannot_find_product_configuration_error(identifiers: missingProducts))
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
