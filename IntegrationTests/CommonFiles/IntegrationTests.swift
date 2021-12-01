//
//  IntegrationTests.swift
//  IntegrationTests
//
//  Created by Andrés Boedo on 10/28/20.
//

import XCTest

#if SPM_INTEGRATION
@testable import SPMIntegration
#elseif CARTHAGE_INTEGRATION
@testable import CarthageIntegration
#elseif COCOAPODS_INTEGRATION
@testable import CocoapodsIntegration
#elseif XCODE_INTEGRATION
@testable import XcodeDirectIntegration
#endif

import RevenueCat

class IntegrationTests: XCTestCase {

    func testCanConfigureTheSDK() throws {
        RCIntegrationRunner().start()
    }

    func testCanFetchCustomerInfo() throws {
        let integrationRunner = RCIntegrationRunner()
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
