//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

typealias ReceiveIntroEligibilityBlock = ([String: IntroEligibility]) -> Void

/// A type that can determine `IntroEligibility` for products.
protocol TrialOrIntroPriceEligibilityCheckerType: Sendable {

    func checkEligibility(productIdentifiers: Set<String>) async -> [String: IntroEligibility]

}
