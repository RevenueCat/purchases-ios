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
    var invokedOfferingsParameters: (appUserID: String, completion: ReceiveOfferingsBlock?)?
    var invokedOfferingsParametersList = [(appUserID: String, completion: ReceiveOfferingsBlock?)]()
    var stubbedOfferingsCompletionResult: (offerings: Offerings?, error: Error?)?
    
    override func offerings(appUserID: String, completion: ReceiveOfferingsBlock?) {
        invokedOfferings = true
        invokedOfferingsCount += 1
        invokedOfferingsParameters = (appUserID, completion)
        invokedOfferingsParametersList.append((appUserID, completion))
        
        completion?(stubbedOfferingsCompletionResult?.offerings, stubbedOfferingsCompletionResult?.error)
    }

    var invokedUpdateOfferingsCache = false
    var invokedUpdateOfferingsCacheCount = 0
    var invokedUpdateOfferingsCacheParameters: (appUserID: String, isAppBackgrounded: Bool, completion: ReceiveOfferingsBlock?)?
    var invokedUpdateOfferingsCachesParametersList = [(appUserID: String, isAppBackgrounded: Bool,  completion: ReceiveOfferingsBlock?)]()
    var stubbedUpdateOfferingsCompletionResult: (offerings: Offerings?, error: Error?)?

    override func updateOfferingsCache(appUserID: String, isAppBackgrounded: Bool, completion: ReceiveOfferingsBlock?) {
        invokedUpdateOfferingsCache = true
        invokedUpdateOfferingsCacheCount += 1
        invokedUpdateOfferingsCacheParameters = (appUserID, isAppBackgrounded, completion)
        invokedUpdateOfferingsCachesParametersList.append((appUserID, isAppBackgrounded, completion))
        
        completion?(stubbedUpdateOfferingsCompletionResult?.offerings, stubbedUpdateOfferingsCompletionResult?.error)
    }
    
}
