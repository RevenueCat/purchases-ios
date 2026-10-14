//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsAPI.swift
//
//  Created by Joshua Liebowitz on 6/15/22.

import Foundation

struct OfferingsFetchResult {
    let contents: Offerings.Contents
    let rawResponseData: Data?
}

class OfferingsAPI {

    typealias IntroEligibilityResponseHandler = ([String: IntroEligibility], BackendError?) -> Void
    typealias OfferSigningResponseHandler = Backend.ResponseHandler<PostOfferForSigningOperation.SigningData>
    typealias OffersSigningResponseHandler = Backend.ResponseHandler<[PostOfferForSigningOperation.SigningResult]>
    typealias OfferingsResponseHandler = Backend.ResponseHandler<OfferingsFetchResult>
    typealias WebOfferingProductsResponseHandler = Backend.ResponseHandler<WebOfferingProductsResponse>

    private let offeringsCallbacksCache: CallbackCache<OfferingsCallback>
    private let webOfferingProductsCallbacksCache: CallbackCache<WebOfferingProductsCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.offeringsCallbacksCache = .init()
        self.webOfferingProductsCallbacksCache = .init()
    }

    func getOfferings(appUserID: String,
                      isAppBackgrounded: Bool,
                      completion: @escaping OfferingsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetOfferingsOperation.createFactory(
            configuration: config,
            offeringsCallbackCache: self.offeringsCallbacksCache
        )

        let offeringsCallback = OfferingsCallback(
            cacheKey: factory.cacheKey,
            completion: completion
        )
        let cacheStatus = self.offeringsCallbacksCache.add(offeringsCallback)

        if cacheStatus == .firstCallbackAddedToList {
            Logger.debug(isAppBackgrounded
                         ? Strings.offering.offerings_stale_updating_in_background
                         : Strings.offering.offerings_stale_updating_in_foreground)
        }

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

    func getWebOfferingProducts(appUserID: String, completion: @escaping WebOfferingProductsResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWebOfferingProductsOperation.createFactory(
            configuration: config,
            webOfferingProductsCallbackCache: self.webOfferingProductsCallbacksCache
        )

        let webProductsCallback = WebOfferingProductsCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.webOfferingProductsCallbacksCache.add(webProductsCallback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

    func getIntroEligibility(appUserID: String,
                             receiptData: Data,
                             productIdentifiers: Set<String>,
                             completion: @escaping IntroEligibilityResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let getIntroEligibilityOperation = GetIntroEligibilityOperation(configuration: config,
                                                                        receiptData: receiptData,
                                                                        productIdentifiers: productIdentifiers,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(getIntroEligibilityOperation)
    }

    // swiftlint:disable:next function_parameter_count
    func post(offerIdForSigning offerIdentifier: String,
              productIdentifier: String,
              subscriptionGroup: String,
              receipt: EncodedAppleReceipt,
              appUserID: String,
              completion: @escaping OfferSigningResponseHandler) {
        let offer = PostOfferForSigningOperation.OfferData(
            offerIdentifier: offerIdentifier,
            productIdentifier: productIdentifier,
            subscriptionGroup: subscriptionGroup
        )
        self.post(
            offersForSigning: [offer],
            receipt: receipt,
            appUserID: appUserID
        ) { result in
            completion(result.flatMap { results in
                guard let firstResult = results.first else {
                    return .failure(.unexpectedBackendResponse(.postOfferIdMissingOffersInResponse))
                }
                return firstResult.result
            })
        }
    }

    func post(
        offersForSigning offers: [PostOfferForSigningOperation.OfferData],
        receipt: EncodedAppleReceipt,
        appUserID: String,
        completion: @escaping OffersSigningResponseHandler
    ) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let postOfferData = PostOfferForSigningOperation.PostOfferForSigningData(
            offers: offers,
            receipt: receipt
        )
        let postOfferForSigningOperation = PostOfferForSigningOperation(configuration: config,
                                                                        postOfferForSigningData: postOfferData,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(postOfferForSigningOperation)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension OfferingsAPI: @unchecked Sendable {}
