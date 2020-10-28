//
//  CarthageIntegrationTests.swift
//  CarthageIntegrationTests
//
//  Created by Andrés Boedo on 10/28/20.
//

import XCTest
import CarthageIntegration

class CarthageIntegrationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        RCIntegrationRunner().start()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
