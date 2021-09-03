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
                  operationDispatcher: MockOperationDispatcher())
    }

    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore = false
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount = 0
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters: (productIdentifiers: [String], Void)?
    var invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList = [(productIdentifiers: [String], Void)]()
    var stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult: ([String: IntroEligibility], Void)?

    override func checkTrialOrIntroPriceEligibilityFromOptimalStoreKitVersion(_ productIdentifiers: [String],
        completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStore = true
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreCount += 1
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParameters = (productIdentifiers, ())
        invokedCheckTrialOrIntroPriceEligibilityFromOptimalStoreParametersList.append((productIdentifiers, ()))
        if let result = stubbedCheckTrialOrIntroPriceEligibilityFromOptimalStoreReceiveEligibilityResult {
            receiveEligibility(result.0)
        }
    }

    var invokedSk1checkTrialOrIntroPriceEligibility = false
    var invokedSk1checkTrialOrIntroPriceEligibilityCount = 0
    var invokedSk1checkTrialOrIntroPriceEligibilityParameters: (productIdentifiers: [String], Void)?
    var invokedSk1checkTrialOrIntroPriceEligibilityParametersList = [(productIdentifiers: [String], Void)]()
    var stubbedSk1checkTrialOrIntroPriceEligibilityReceiveEligibilityResult: ([String: IntroEligibility], Void)?

    override func sk1checkTrialOrIntroPriceEligibility(_ productIdentifiers: [String],
        completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        invokedSk1checkTrialOrIntroPriceEligibility = true
        invokedSk1checkTrialOrIntroPriceEligibilityCount += 1
        invokedSk1checkTrialOrIntroPriceEligibilityParameters = (productIdentifiers, ())
        invokedSk1checkTrialOrIntroPriceEligibilityParametersList.append((productIdentifiers, ()))
        if let result = stubbedSk1checkTrialOrIntroPriceEligibilityReceiveEligibilityResult {
            receiveEligibility(result.0)
        }
    }

    var invokedSk2checkTrialOrIntroPriceEligibility = false
    var invokedSk2checkTrialOrIntroPriceEligibilityCount = 0
    var invokedSk2checkTrialOrIntroPriceEligibilityParameters: (productIdentifiers: [String], Void)?
    var invokedSk2checkTrialOrIntroPriceEligibilityParametersList = [(productIdentifiers: [String], Void)]()
    var stubbedSk2checkTrialOrIntroPriceEligibilityReceiveEligibilityResult: ([String: IntroEligibility], Void)?

    override func sk2checkTrialOrIntroPriceEligibility(_ productIdentifiers: [String],
        completionBlock receiveEligibility: @escaping ReceiveIntroEligibilityBlock) {
        invokedSk2checkTrialOrIntroPriceEligibility = true
        invokedSk2checkTrialOrIntroPriceEligibilityCount += 1
        invokedSk2checkTrialOrIntroPriceEligibilityParameters = (productIdentifiers, ())
        invokedSk2checkTrialOrIntroPriceEligibilityParametersList.append((productIdentifiers, ()))
        if let result = stubbedSk2checkTrialOrIntroPriceEligibilityReceiveEligibilityResult {
            receiveEligibility(result.0)
        }
    }
}
