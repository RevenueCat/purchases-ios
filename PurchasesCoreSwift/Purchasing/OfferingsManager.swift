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

public typealias ReceiveOfferingsBlock = (Offerings?, Error?) -> Void

// TODO (post-migration): Make all the things internal again.
@objc(RCOfferingsManager) public class OfferingsManager: NSObject {

    private let deviceCache: DeviceCache
    private let operationDispatcher: OperationDispatcher
    private let systemInfo: SystemInfo
    private let backend: Backend
    private let offeringsFactory: OfferingsFactory
    private let productsManager: ProductsManager

    @objc public init(deviceCache: DeviceCache,
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

}

public extension OfferingsManager {

    @objc(offeringsWithAppUserID:completionBlock:)
    func offerings(appUserID: String, completion: ReceiveOfferingsBlock?) {
        guard let cachedOfferings = deviceCache.cachedOfferings else {
            Logger.debug(Strings.offering.no_cached_offerings_fetching_from_network)
            systemInfo.isApplicationBackgrounded { isAppBackgrounded in
                self.updateOfferingsCache(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded, completion: completion)
            }
            return
        }

        Logger.debug(Strings.offering.vending_offerings_cache)
        if let completion = completion {
            operationDispatcher.dispatchOnMainThread {
                completion(cachedOfferings, nil)
            }
        }

        systemInfo.isApplicationBackgrounded { isAppBackgrounded in
            if self.deviceCache.isOfferingsCacheStale(isAppBackgrounded: isAppBackgrounded) {
                Logger.debug(isAppBackgrounded
                                ? Strings.offering.offerings_stale_updating_in_background
                                : Strings.offering.offerings_stale_updating_in_foreground)
                self.updateOfferingsCache(appUserID: appUserID, isAppBackgrounded: isAppBackgrounded, completion: nil)
                Logger.rcSuccess(Strings.offering.offerings_stale_updated_from_network)
            }
        }
    }

    @objc(updateOfferingsCacheWithAppUserID:isAppBackgrounded:completion:)
    func updateOfferingsCache(appUserID: String, isAppBackgrounded: Bool, completion: ReceiveOfferingsBlock?) {
        deviceCache.setOfferingsCacheTimestampToNow()
        operationDispatcher.dispatchOnWorkerThread(withRandomDelay: isAppBackgrounded) {
            self.backend.getOfferings(appUserID: appUserID) { data, error in
                if let data = data {
                    self.handleOfferingsBackendResult(with: data, completion: completion)
                } else if let error = error {
                    self.handleOfferingsUpdateError(error, completion: completion)
                }
            }
        }
    }

}

private extension OfferingsManager {

    func handleOfferingsBackendResult(with data: [String: Any], completion: ReceiveOfferingsBlock?) {
        var productIdentifiers = Set<String>()
        performOnEachProductIdentifierInOfferings(data) { productIdentifier in
            productIdentifiers.insert(productIdentifier)
        }

        productsManager.products(withIdentifiers: productIdentifiers) { products in
            let productsByID = products.reduce(into: [:]) { result, product in
                result[product.productIdentifier] = product
            }

            if let createdOfferings = self.offeringsFactory.createOfferings(withProducts: productsByID, data: data) {

                var missingProducts = [String]()
                self.performOnEachProductIdentifierInOfferings(data) { productIdentifier in
                    if productsByID.keys.contains(productIdentifier) {
                        missingProducts.append(productIdentifier)
                    }
                }

                if !missingProducts.isEmpty {
                    Logger.appleWarning(Strings.offering.cannot_find_product_configuration_error)
                }

                self.deviceCache.cache(offerings: createdOfferings)
                if let completion = completion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(createdOfferings, nil)
                    }
                }
            } else {
                self.handleOfferingsUpdateError(ErrorUtils.unexpectedBackendResponseError(), completion: completion)
            }
        }
    }

    func handleOfferingsUpdateError(_ error: Error, completion: ReceiveOfferingsBlock?) {
        Logger.appleError(String(format: Strings.offering.fetching_offerings_error, error as CVarArg))
        deviceCache.clearOfferingsCacheTimestamp()
        if let completion = completion {
            operationDispatcher.dispatchOnMainThread {
                completion(nil, error)
            }
        }
    }

    func performOnEachProductIdentifierInOfferings(_ offeringsData: [String: Any], block: (String) -> Void) {
        guard let offerings = offeringsData["offerings"] as? [[String: Any]] else {
            return
        }

        offerings
            .compactMap { $0["packages"] as? [[String: Any]] }
            .flatMap { $0 }
            .compactMap { $0["platform_product_identifier"] as? String }
            .forEach {
                block($0)
            }
    }

}
