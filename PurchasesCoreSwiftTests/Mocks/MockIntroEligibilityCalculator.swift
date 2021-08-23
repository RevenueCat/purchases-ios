//
//  MockIntroEligibilityCalculator.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 8/4/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
@testable import Purchases
@testable import PurchasesCoreSwift

class MockIntroEligibilityCalculator: PurchasesCoreSwift.IntroEligibilityCalculator {

    var invokedCheckTrialOrIntroductoryPriceEligibility = false
    var invokedCheckTrialOrIntroductoryPriceEligibilityCount = 0
    var invokedCheckTrialOrIntroductoryPriceEligibilityParameters: (receiptData: Data, candidateProductIdentifiers: Set<String>)?
    var invokedCheckTrialOrIntroductoryPriceEligibilityParametersList = [(receiptData: Data,
        candidateProductIdentifiers: Set<String>)]()
    var stubbedCheckTrialOrIntroductoryPriceEligibilityCompletionResult: ([String: NSNumber], Error?)?

    @available(iOS 12.0, macOS 10.14, macCatalyst 13.0, tvOS 12.0, watchOS 6.2, *)
    override func checkTrialOrIntroductoryPriceEligibility(with receiptData: Data,
                                                           productIdentifiers candidateProductIdentifiers: Set<String>,
                                                           completion: @escaping ([String: NSNumber], Error?) -> ()) {
        invokedCheckTrialOrIntroductoryPriceEligibility = true
        invokedCheckTrialOrIntroductoryPriceEligibilityCount += 1
        invokedCheckTrialOrIntroductoryPriceEligibilityParameters = (receiptData, candidateProductIdentifiers)
        invokedCheckTrialOrIntroductoryPriceEligibilityParametersList.append((receiptData, candidateProductIdentifiers))
        if let result = stubbedCheckTrialOrIntroductoryPriceEligibilityCompletionResult {
            completion(result.0, result.1)
        }
    }
}
