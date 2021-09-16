//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTrialOrIntroPriceEligibilityChecker.swift
//
//  Created by César de la Vega on 9/1/21.

@testable import RevenueCat

class MockTrialOrIntroPriceEligibilityChecker: TrialOrIntroPriceEligibilityChecker {
    
    convenience init() {
        self.init(receiptFetcher: MockReceiptFetcher(requestFetcher: MockRequestFetcher()),
                  introEligibilityCalculator: MockIntroEligibilityCalculator(),
                  backend: MockBackend(),
                  identityManager: MockIdentityManager(mockAppUserID: "app_user"),
                  operationDispatcher: MockOperationDispatcher(),
                  productsManager: MockProductsManager())
    }
    
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore = false
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount = 0
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters: (productIdentifiers: [String], Void)?
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList = [(productIdentifiers: [String], Void)]()
    var stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult: [String: IntroEligibility] = [:]
    
    override func checkEligibility(productIdentifiers: [String],
                                   completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore = true
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount += 1
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters = (productIdentifiers, ())
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList.append((productIdentifiers, ()))
        receiveEligibility(stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult)
    }
    
    var invokedSk1checkTrialOrIntroPriceEligibility = false
    var invokedSk1checkTrialOrIntroPriceEligibilityCount = 0
    var invokedSk1checkTrialOrIntroPriceEligibilityParameters: (productIdentifiers: [String], Void)?
    var invokedSk1checkTrialOrIntroPriceEligibilityParametersList = [(productIdentifiers: [String], Void)]()
    var stubbedSk1checkTrialOrIntroPriceEligibilityReceiveEligibilityResult: [String: IntroEligibility] = [:]
    
    override func sk1CheckEligibility(_ productIdentifiers: [String],
                                      completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        invokedSk1checkTrialOrIntroPriceEligibility = true
        invokedSk1checkTrialOrIntroPriceEligibilityCount += 1
        invokedSk1checkTrialOrIntroPriceEligibilityParameters = (productIdentifiers, ())
        invokedSk1checkTrialOrIntroPriceEligibilityParametersList.append((productIdentifiers, ()))
        receiveEligibility(stubbedSk1checkTrialOrIntroPriceEligibilityReceiveEligibilityResult)
    }
    
    var invokedSk2checkTrialOrIntroPriceEligibility = false
    var invokedSk2checkTrialOrIntroPriceEligibilityCount = 0
    var invokedSk2checkTrialOrIntroPriceEligibilityParameters: (productIdentifiers: [String], Void)?
    var invokedSk2checkTrialOrIntroPriceEligibilityParametersList = [(productIdentifiers: [String], Void)]()
    var stubbedSk2checkTrialOrIntroPriceEligibilityReceiveEligibilityResult: [String: IntroEligibility] = [:]
    
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    override func sk2CheckEligibility(_ productIdentifiers: [String]) async -> [String : IntroEligibility] {
        invokedSk2checkTrialOrIntroPriceEligibility = true
        invokedSk2checkTrialOrIntroPriceEligibilityCount += 1
        invokedSk2checkTrialOrIntroPriceEligibilityParameters = (productIdentifiers, ())
        invokedSk2checkTrialOrIntroPriceEligibilityParametersList.append((productIdentifiers, ()))
        
        return stubbedSk2checkTrialOrIntroPriceEligibilityReceiveEligibilityResult
    }
}
