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

class MockOfferingsManager: OfferingsManager {

    var invokedOfferings = false
    var invokedOfferingsCount = 0
    var invokedOfferingsParameters: (appUserID: String, completion: ((Offerings?, Error?) -> Void)?)?
    var invokedOfferingsParametersList = [(appUserID: String, completion: ((Offerings?, Error?) -> Void)?)]()
    var stubbedOfferingsCompletionResult: (offerings: Offerings?, error: Error?)?

    override func offerings(appUserID: String, completion: ((Offerings?, Error?) -> Void)?) {
        invokedOfferings = true
        invokedOfferingsCount += 1
        invokedOfferingsParameters = (appUserID, completion)
        invokedOfferingsParametersList.append((appUserID, completion))

        completion?(stubbedOfferingsCompletionResult?.offerings, stubbedOfferingsCompletionResult?.error)
    }

    struct InvokedUpdateOfferingsCacheParameters {
        let appUserID: String
        let isAppBackgrounded: Bool
        let completion: ((Offerings?, Error?) -> Void)?
    }

    var invokedUpdateOfferingsCache = false
    var invokedUpdateOfferingsCacheCount = 0
    var invokedUpdateOfferingsCacheParameters: InvokedUpdateOfferingsCacheParameters?
    var invokedUpdateOfferingsCachesParametersList = [InvokedUpdateOfferingsCacheParameters]()
    var stubbedUpdateOfferingsCompletionResult: (offerings: Offerings?, error: Error?)?

    override func updateOfferingsCache(
        appUserID: String,
        isAppBackgrounded: Bool,
        completion: ((Offerings?, Error?) -> Void)?
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

        completion?(stubbedUpdateOfferingsCompletionResult?.offerings, stubbedUpdateOfferingsCompletionResult?.error)
    }

}
