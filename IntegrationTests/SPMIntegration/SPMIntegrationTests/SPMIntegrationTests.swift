//
//  SPMIntegrationTests.swift
//  SPMIntegrationTests
//
//  Created by Andrés Boedo on 10/28/20.
//

import XCTest
@testable import SPMIntegration
import Purchases

class SPMIntegrationTests: XCTestCase {

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
