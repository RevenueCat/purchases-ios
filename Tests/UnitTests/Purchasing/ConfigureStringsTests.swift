//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConfigureStringsTests.swift
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class ConfigureStringsTests: TestCase {

    func testIsSimulatorAppStoreReferencesStoreKitConfig() {
        let subject = Strings.configure.is_simulator(true, apiKeyValidationResult: .validApplePlatform)

        expect(subject.category).to(equal("configure"))
        expect(subject.description).to(contain("StoreKit Config"))
        expect(subject.description).to(contain("https://errors.rev.cat/testing-in-simulator"))
    }

    func testIsSimulatorSimulatedStoreDoesNotReferenceStoreKitConfig() {
        let subject = Strings.configure.is_simulator(true, apiKeyValidationResult: .simulatedStore)

        expect(subject.category).to(equal("configure"))
        expect(subject.description).to(contain("Test Store"))
        expect(subject.description).toNot(contain("StoreKit Config"))
        expect(subject.description).toNot(contain("StoreKit Configuration"))
    }

    func testIsSimulatorFalseDoesNotReferenceStoreKit() {
        let subject = Strings.configure.is_simulator(false, apiKeyValidationResult: .simulatedStore)

        expect(subject.category).to(equal("configure"))
        expect(subject.description).to(equal("Not using a simulator."))
    }

}
