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

    // MARK: - cannot_find_product_configuration_error

    func testCannotFindProductConfigurationErrorAppStoreReferencesAppStoreConnect() {
        let subject = Strings.offering
            .cannot_find_product_configuration_error(identifiers: ["com.x.product"],
                                                     apiKeyValidationResult: .validApplePlatform)

        expect(subject.description).to(contain("com.x.product"))
        expect(subject.description).to(contain("App Store Connect"))
    }

    func testCannotFindProductConfigurationErrorSimulatedStoreDoesNotReferenceAppStore() {
        let subject = Strings.offering
            .cannot_find_product_configuration_error(identifiers: ["com.x.product"],
                                                     apiKeyValidationResult: .simulatedStore)

        expect(subject.description).to(contain("com.x.product"))
        expect(subject.description).to(contain("Test Store"))
        expect(subject.description).toNot(contain("App Store Connect"))
        expect(subject.description).toNot(contain("StoreKit Config"))
    }

    // MARK: - configuration_error_products_not_found

    func testConfigurationErrorProductsNotFoundAppStoreReferencesAppStoreConnect() {
        let subject = Strings.offering
            .configuration_error_products_not_found(apiKeyValidationResult: .validApplePlatform)

        expect(subject.description).to(contain("App Store Connect"))
    }

    func testConfigurationErrorProductsNotFoundSimulatedStoreDoesNotReferenceAppStore() {
        let subject = Strings.offering
            .configuration_error_products_not_found(apiKeyValidationResult: .simulatedStore)

        expect(subject.description).to(contain("Test Store"))
        expect(subject.description).toNot(contain("App Store Connect"))
        expect(subject.description).toNot(contain("StoreKit Config"))
    }

    // MARK: - known_issue_ios_18_4_simulator_products_not_found

    func testKnownIssue1840SimulatorProductsNotFoundAppStoreReferencesAppStoreConnect() {
        let subject = Strings.offering
            .known_issue_ios_18_4_simulator_products_not_found(apiKeyValidationResult: .validApplePlatform)

        expect(subject.description).to(contain("App Store Connect"))
    }

    func testKnownIssue1840SimulatorProductsNotFoundSimulatedStoreDoesNotReferenceAppStore() {
        let subject = Strings.offering
            .known_issue_ios_18_4_simulator_products_not_found(apiKeyValidationResult: .simulatedStore)

        expect(subject.description).to(contain("Test Store"))
        expect(subject.description).toNot(contain("App Store Connect"))
        expect(subject.description).toNot(contain("StoreKit Config"))
    }

}
