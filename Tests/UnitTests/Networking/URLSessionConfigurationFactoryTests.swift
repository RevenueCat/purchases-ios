//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLSessionConfigurationFactoryTests.swift
//
//  Created by Andrés Boedo on 5/29/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class URLSessionConfigurationFactoryTests: TestCase {

    var factory: URLSessionConfigurationFactory!

    override func setUp() {
        super.setUp()
        factory = URLSessionConfigurationFactory()
    }

    override func tearDown() {
        factory = nil
        super.tearDown()
    }

    func testHttpMaximumConnectionsPerHost() {
        let config = factory.urlSessionConfiguration(requestTimeout: 30.0)

        expect(config.httpMaximumConnectionsPerHost) == 1
    }

    func testTimeoutIntervalForRequest() {
        let requestTimeout: TimeInterval = 30.0
        let config = factory.urlSessionConfiguration(requestTimeout: requestTimeout)

        expect(config.timeoutIntervalForRequest) == requestTimeout
    }

    func testTimeoutIntervalForResource() {
        let requestTimeout: TimeInterval = 30.0
        let config = factory.urlSessionConfiguration(requestTimeout: requestTimeout)

        expect(config.timeoutIntervalForResource) == requestTimeout
    }

    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testRequiresDNSSECValidation() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
        let config = factory.urlSessionConfiguration(requestTimeout: 30.0)

        expect(config.requiresDNSSECValidation) == true
    }

}
