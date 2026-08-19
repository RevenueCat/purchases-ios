//
//  InstallationTests.swift
//  InstallationTests
//
//  Created by Andrés Boedo on 10/28/20.
//

import XCTest

#if SPM_INSTALLATION
@testable import SPMInstallation
#elseif CARTHAGE_INSTALLATION
@testable import CarthageInstallation
#elseif COCOAPODS_INSTALLATION
@testable import CocoapodsInstallation
#elseif XCODE_INSTALLATION
@testable import XcodeDirectInstallation
#endif

@_spi(Internal) import RevenueCat

class InstallationTests: XCTestCase {

    func testCanConfigureTheSDK() throws {
        RCInstallationRunner().start()
    }

    func testCanFetchCustomerInfo() throws {
        let installationRunner = RCInstallationRunner()
        installationRunner.start()
        let expectation = XCTestExpectation(description: "get CustomerInfo")

        installationRunner.getCustomerInfo { customerInfo, error in
            XCTAssertNil(error)
            XCTAssertNotNil(customerInfo)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testInstallationMethodIsDetectedCorrectly() throws {
        #if SPM_INSTALLATION
        let expected = "spm"
        #elseif COCOAPODS_INSTALLATION
        let expected = "cocoapods"
        #elseif CARTHAGE_INSTALLATION
        let expected = "unknown"
        #elseif XCODE_INSTALLATION
        let expected = "unknown"
        #else
        let expected = "unknown"
        #endif

        XCTAssertEqual(Purchases.installationMethod, expected)
    }
}
