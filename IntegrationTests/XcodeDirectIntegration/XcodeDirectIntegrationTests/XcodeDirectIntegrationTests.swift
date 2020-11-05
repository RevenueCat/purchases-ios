//
//  XcodeDirectIntegrationTests.swift
//  XcodeDirectIntegrationTests
//
//  Created by Andrés Boedo on 10/28/20.
//

import XCTest
import XcodeDirectIntegration
import Purchases

class XcodeDirectIntegrationTests: XCTestCase {

    func testCanConfigureTheSDK() throws {
        RCIntegrationRunner().start()
    }

    func testCanFetchPurchaserInfo() throws {
        let integrationRunner = RCIntegrationRunner()
        integrationRunner.start()
        let expectation = XCTestExpectation(description: "get purchaserInfo")

        integrationRunner.purchaserInfo { (purchaserInfo, error) in
            XCTAssert(error == nil)
            XCTAssert(purchaserInfo != nil)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
