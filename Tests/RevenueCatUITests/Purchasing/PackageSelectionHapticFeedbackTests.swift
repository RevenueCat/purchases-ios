//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageSelectionHapticFeedbackTests.swift

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCatUI
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PackageSelectionHapticFeedbackTests: TestCase {

    func testCallAsFunctionInvokesTheInjectedAction() {
        var didFire = false

        let feedback = PackageSelectionHapticFeedback { didFire = true }
        feedback()

        expect(didFire) == true
    }

    func testCallAsFunctionInvokesTheActionExactlyOncePerCall() {
        var fireCount = 0

        let feedback = PackageSelectionHapticFeedback { fireCount += 1 }
        feedback()
        feedback()
        feedback()

        expect(fireCount) == 3
    }

}
