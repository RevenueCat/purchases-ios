//
//  CocoapodsIntegrationTests.swift
//  CocoapodsIntegrationTests
//
//  Created by Andrés Boedo on 10/27/20.
//

import XCTest
@testable import CocoapodsIntegration
import Purchases

class CocoapodsIntegrationTests: XCTestCase {

    func testCanConfigureTheSDK() throws {
        RCIntegrationRunner().start()
    }

    func testCanFetchPurchaserInfo() throws {
        let integrationRunner = RCIntegrationRunner()
        integrationRunner.start()
        let expectation = XCTestExpectation(description: "Download apple.com home page")

        integrationRunner.purchaserInfo { (purchaserInfo, error) in
            XCTAssert(error == nil)
            XCTAssert(purchaserInfo != nil)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
