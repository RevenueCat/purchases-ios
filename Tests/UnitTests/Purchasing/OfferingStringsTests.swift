//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingStringsTests.swift
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class OfferingStringsTests: TestCase {

    func testOfferingEmptyAppStoreReferencesAppStoreConnect() {
        let subject = Strings.offering
            .offering_empty(offeringIdentifier: "my_offering", apiKeyValidationResult: .validApplePlatform)

        expect(subject.category).to(equal("offering"))
        expect(subject.description).to(contain("my_offering"))
        expect(subject.description).to(contain("App Store Connect"))
    }

    func testOfferingEmptySimulatedStoreDoesNotReferenceAppStore() {
        let subject = Strings.offering
            .offering_empty(offeringIdentifier: "my_offering", apiKeyValidationResult: .simulatedStore)

        expect(subject.category).to(equal("offering"))
        expect(subject.description).to(contain("my_offering"))
        expect(subject.description).to(contain("Test Store"))
        expect(subject.description).toNot(contain("App Store Connect"))
        expect(subject.description).toNot(contain("StoreKit Configuration"))
    }

    func testOfferingEmptyOtherPlatformsDoesNotReferenceAppStore() {
        let subject = Strings.offering
            .offering_empty(offeringIdentifier: "my_offering", apiKeyValidationResult: .otherPlatforms)

        expect(subject.category).to(equal("offering"))
        expect(subject.description).to(contain("my_offering"))
        expect(subject.description).toNot(contain("App Store Connect"))
        expect(subject.description).toNot(contain("StoreKit Configuration"))
    }

}
