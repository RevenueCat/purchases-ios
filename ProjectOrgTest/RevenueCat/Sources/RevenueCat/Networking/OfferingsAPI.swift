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

class OfferingsAPI {

    typealias IntroEligibilityResponseHandler = ([String: IntroEligibility], BackendError?) -> Void
    typealias OfferSigningResponseHandler = Backend.ResponseHandler<PostOfferForSigningOperation.SigningData>
    typealias OfferingsResponseHandler = Backend.ResponseHandler<OfferingsResponse>

    private let offeringsCallbacksCache: CallbackCache<OfferingsCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.offeringsCallbacksCache = .init()
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

        let offeringsCallback = OfferingsCallback(cacheKey: factory.cacheKey, completion: completion)
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
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let postOfferData = PostOfferForSigningOperation.PostOfferForSigningData(offerIdentifier: offerIdentifier,
                                                                                 productIdentifier: productIdentifier,
                                                                                 subscriptionGroup: subscriptionGroup,
                                                                                 receipt: receipt)
        let postOfferForSigningOperation = PostOfferForSigningOperation(configuration: config,
                                                                        postOfferForSigningData: postOfferData,
                                                                        responseHandler: completion)
        self.backendConfig.operationQueue.addOperation(postOfferForSigningOperation)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension OfferingsAPI: @unchecked Sendable {}
