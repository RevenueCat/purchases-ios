//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfferingsAPI.swift
//
//  Created by Joshua Liebowitz on 6/17/22.

import Foundation
@testable import RevenueCat

// swiftlint:disable line_length large_tuple
class MockOfferingsAPI: OfferingsAPI {

    var invokedGetIntroEligibility = false
    var invokedGetIntroEligibilityCount = 0
    var invokedGetIntroEligibilityParameters: (appUserID: String?, receiptData: Data?, productIdentifiers: Set<String>?, completion: OfferingsAPI.IntroEligibilityResponseHandler?)?
    var invokedGetIntroEligibilityParametersList = [(appUserID: String?,
                                                     receiptData: Data?,
                                                     productIdentifiers: Set<String>?,
                                                     completion: OfferingsAPI.IntroEligibilityResponseHandler?)]()
    var stubbedGetIntroEligibilityCompletionResult: (eligibilities: [String: IntroEligibility], error: BackendError?)?

    override func getIntroEligibility(appUserID: String,
                                      receiptData: Data,
                                      productIdentifiers: Set<String>,
                                      completion: @escaping IntroEligibilityResponseHandler) {
        self.invokedGetIntroEligibility = true
        self.invokedGetIntroEligibilityCount += 1
        self.invokedGetIntroEligibilityParameters = (appUserID, receiptData, productIdentifiers, completion)
        self.invokedGetIntroEligibilityParametersList.append((appUserID, receiptData, productIdentifiers, completion))
        completion(self.stubbedGetIntroEligibilityCompletionResult?.eligibilities ?? [:], self.stubbedGetIntroEligibilityCompletionResult?.error)
    }

    var invokedGetOfferingsForAppUserID = false
    var invokedGetOfferingsForAppUserIDCount = 0
    var invokedGetOfferingsForAppUserIDParameters: (appUserID: String?, isAppBackgrounded: Bool, completion: OfferingsAPI.OfferingsResponseHandler?)?
    var invokedGetOfferingsForAppUserIDParametersList = [(appUserID: String?, isAppBackgrounded: Bool, completion: OfferingsAPI.OfferingsResponseHandler?)]()
    var stubbedGetOfferingsCompletionResult: Result<OfferingsResponse, BackendError>?

    override func getOfferings(appUserID: String,
                               isAppBackgrounded: Bool,
                               completion: @escaping OfferingsResponseHandler) {
        self.invokedGetOfferingsForAppUserID = true
        self.invokedGetOfferingsForAppUserIDCount += 1
        self.invokedGetOfferingsForAppUserIDParameters = (appUserID, isAppBackgrounded, completion)
        self.invokedGetOfferingsForAppUserIDParametersList.append((appUserID, isAppBackgrounded, completion))

        completion(self.stubbedGetOfferingsCompletionResult!)
    }

    var invokedPostOffer = false
    var invokedPostOfferCount = 0
    var invokedPostOfferParameters: (offerIdentifier: String?, productIdentifier: String?, subscriptionGroup: String?, data: EncodedAppleReceipt?, applicationUsername: String?, completion: OfferingsAPI.OfferSigningResponseHandler?)?
    var invokedPostOfferParametersList = [(offerIdentifier: String?,
                                           productIdentifier: String?,
                                           subscriptionGroup: String?,
                                           data: EncodedAppleReceipt?,
                                           applicationUsername: String?,
                                           completion: OfferingsAPI.OfferSigningResponseHandler?)]()
    var stubbedPostOfferCompletionResult: Result<PostOfferForSigningOperation.SigningData, BackendError>?

    override func post(offerIdForSigning offerIdentifier: String,
                       productIdentifier: String,
                       subscriptionGroup: String?,
                       receiptData: EncodedAppleReceipt,
                       appUserID: String,
                       completion: @escaping OfferingsAPI.OfferSigningResponseHandler) {
        self.invokedPostOffer = true
        self.invokedPostOfferCount += 1
        self.invokedPostOfferParameters = (offerIdentifier,
                                           productIdentifier,
                                           subscriptionGroup,
                                           receiptData,
                                           appUserID,
                                           completion)
        self.invokedPostOfferParametersList.append((offerIdentifier,
                                                    productIdentifier,
                                                    subscriptionGroup,
                                                    receiptData,
                                                    appUserID,
                                                    completion))

        completion(self.stubbedPostOfferCompletionResult ?? .failure(.missingAppUserID()))
    }

}
