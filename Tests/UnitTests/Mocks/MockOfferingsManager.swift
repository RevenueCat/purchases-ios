//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfferingsManager.swift
//
//  Created by Juanpe Catalán on 8/8/21.

import Foundation
@testable import RevenueCat

// swiftlint:disable identifier_name
class MockOfferingsManager: OfferingsManager {

    var invokedOfferings = false
    var invokedOfferingsCount = 0
    var invokedOfferingsParameters: (appUserID: String, completion: ((Result<Offerings, Error>) -> Void)?)?
    var invokedOfferingsParametersList = [(appUserID: String, completion: ((Result<Offerings, Error>) -> Void)?)]()
    var stubbedOfferingsCompletionResult: Result<Offerings, Error>?

    override func offerings(appUserID: String, completion: ((Result<Offerings, Error>) -> Void)?) {
        invokedOfferings = true
        invokedOfferingsCount += 1
        invokedOfferingsParameters = (appUserID, completion)
        invokedOfferingsParametersList.append((appUserID, completion))

        completion?(stubbedOfferingsCompletionResult!)
    }

    struct InvokedUpdateOfferingsCacheParameters {
        let appUserID: String
        let isAppBackgrounded: Bool
        let completion: ((Result<Offerings, Error>) -> Void)?
    }

    var invokedUpdateOfferingsCache = false
    var invokedUpdateOfferingsCacheCount = 0
    var invokedUpdateOfferingsCacheParameters: InvokedUpdateOfferingsCacheParameters?
    var invokedUpdateOfferingsCachesParametersList = [InvokedUpdateOfferingsCacheParameters]()
    var stubbedUpdateOfferingsCompletionResult: Result<Offerings, Error>?

    override func updateOfferingsCache(
        appUserID: String,
        isAppBackgrounded: Bool,
        completion: ((Result<Offerings, Error>) -> Void)?
    ) {
        invokedUpdateOfferingsCache = true
        invokedUpdateOfferingsCacheCount += 1

        let parameters = InvokedUpdateOfferingsCacheParameters(
            appUserID: appUserID,
            isAppBackgrounded: isAppBackgrounded,
            completion: completion
        )

        invokedUpdateOfferingsCacheParameters = parameters
        invokedUpdateOfferingsCachesParametersList.append(parameters)

        completion?(stubbedUpdateOfferingsCompletionResult!)
    }

    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiate = false
    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount = 0
    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParameters: String?
    var invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParametersList = [String]()

    override func invalidateAndReFetchCachedOfferingsIfAppropiate(appUserID: String) {
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiate = true
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiateCount += 1
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParameters = appUserID
        invokedInvalidateAndReFetchCachedOfferingsIfAppropiateParametersList.append(appUserID)
    }

}
