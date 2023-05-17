//
//  InstallationTests.swift
//  InstallationTests
//
//  Created by Nacho Soto on 4/25/23.
//

import XCTest

import RevenueCat_CustomEntitlementComputation

class InstallationTests: XCTestCase {

    override func setUp() {
        super.setUp()

        Purchases.logLevel = .debug

        let proxyURL = ""
        if proxyURL != "", !proxyURL.isEmpty {
            Purchases.proxyURL = URL(string: proxyURL)!
        }

        Purchases.configureInCustomEntitlementsComputationMode(apiKey: "rGogYWEdzrENUEzEoYXZNUkzoPEbEvfb",
                                                               appUserID: "Integration Tests")
    }

    func testCanSwitchUser() throws {
        let userID = "new_user_ID"

        Purchases.shared.switchUser(to: userID)
        XCTAssertEqual(Purchases.shared.appUserID, userID)
    }

}
