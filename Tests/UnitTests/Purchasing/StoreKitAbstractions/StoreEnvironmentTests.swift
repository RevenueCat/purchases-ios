//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreEnvironmentTests.swift
//
//  Created by Mark Villacampa on 11/15/23.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

@MainActor
class StoreEnvironmentTests: TestCase {

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testFromAppStoreEnvironment() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        expect(StoreEnvironment(environment: .production)) == .production
        expect(StoreEnvironment(environment: .sandbox)) == .sandbox
        expect(StoreEnvironment(environment: .xcode)) == .xcode
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testFromUnknownAppStoreEnvironment() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let environment = StoreKit.AppStore.Environment(rawValue: "revenuecat")
        expect(StoreEnvironment(environment: environment)).to(beNil())

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.sk2_unknown_environment(String(environment.rawValue)),
            level: .warn
        )
    }

    func testStoreEnvironmentFromString() {
        expect(StoreEnvironment(environment: "Production")) == .production
        expect(StoreEnvironment(environment: "Sandbox")) == .sandbox
        expect(StoreEnvironment(environment: "Xcode")) == .xcode
    }

    func testFromUnknownString() {
        expect(StoreEnvironment(environment: "revenuecat")).to(beNil())

        self.logger.verifyMessageWasLogged(
            Strings.storeKit.sk2_unknown_environment("revenuecat"),
            level: .warn
        )
    }

}
