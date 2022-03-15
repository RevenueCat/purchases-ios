//
//  InstallationTests.swift
//  InstallationTests
//
//  Created by Andrés Boedo on 10/28/20.
//

import XCTest

#if SPM_INTEGRATION
@testable import SPMIntegration
#elseif CARTHAGE_INSTALLATION
@testable import CarthageInstallation
#elseif COCOAPODS_INSTALLATION
@testable import CocoapodsInstallation
#elseif XCODE_INTEGRATION
@testable import XcodeDirectIntegration
#endif

import RevenueCat

class InstallationTests: XCTestCase {

    func testCanConfigureTheSDK() throws {
        RCInstallationRunner().start()
    }

    func testCanFetchCustomerInfo() throws {
        let integrationRunner = RCInstallationRunner()
        integrationRunner.start()
        let expectation = XCTestExpectation(description: "get purchaserInfo")

        integrationRunner.getCustomerInfo { (customerInfo, error) in
            XCTAssert(error == nil)
            XCTAssert(customerInfo != nil)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
