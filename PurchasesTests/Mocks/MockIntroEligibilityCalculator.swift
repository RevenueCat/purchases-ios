//
//  MockIntroEligibilityCalculator.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 8/4/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@testable import RevenueCat

// swiftlint:disable identifier_name
// swiftlint:disable line_length
class MockIntroEligibilityCalculator: IntroEligibilityCalculator {

    var invokedCheckTrialOrIntroductoryPriceEligibility = false
    var invokedCheckTrialOrIntroductoryPriceEligibilityCount = 0
    var invokedCheckTrialOrIntroductoryPriceEligibilityParameters: (receiptData: Data, candidateProductIdentifiers: Set<String>)?
    var invokedCheckTrialOrIntroductoryPriceEligibilityParametersList = [(receiptData: Data,
                                                                          candidateProductIdentifiers: Set<String>)]()
    var stubbedCheckTrialOrIntroductoryPriceEligibilityResult: ([String: IntroEligibilityStatus], Error?)?

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    override func checkEligibility(with receiptData: Data,
                                   productIdentifiers candidateProductIdentifiers: Set<String>,
                                   completion: @escaping ([String: IntroEligibilityStatus], Error?) -> Void) {
        invokedCheckTrialOrIntroductoryPriceEligibility = true
        invokedCheckTrialOrIntroductoryPriceEligibilityCount += 1
        invokedCheckTrialOrIntroductoryPriceEligibilityParameters = (receiptData, candidateProductIdentifiers)
        invokedCheckTrialOrIntroductoryPriceEligibilityParametersList.append((receiptData, candidateProductIdentifiers))
        if let result = stubbedCheckTrialOrIntroductoryPriceEligibilityResult {
            completion(result.0, result.1)
        }
    }

}
