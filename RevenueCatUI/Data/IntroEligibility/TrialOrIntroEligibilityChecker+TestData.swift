//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TrialOrIntroEligibilityChecker+TestData.swift
//
//  Created by Nacho Soto on 9/12/23.

import Foundation
import RevenueCat

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TrialOrIntroEligibilityChecker {

    /// Creates a mock `TrialOrIntroEligibilityChecker` with a constant result.
    static func producing(eligibility: @autoclosure @escaping () -> IntroEligibilityStatus) -> Self {
        return .init { packages in
            return Dictionary(
                uniqueKeysWithValues: Set(packages)
                    .map { package in
                        let result = package.storeProduct.hasIntroDiscount
                        ? eligibility()
                        : .noIntroOfferExists

                        return (package, result)
                    }
            )
        }
    }

    /// Creates a copy of this `TrialOrIntroEligibilityChecker` with a delay.
    func with(delay seconds: TimeInterval) -> Self {
        return .init { [checker = self.checker] in
            await Task.sleep(seconds: seconds)

            return await checker($0)
        }
    }

}

#endif
