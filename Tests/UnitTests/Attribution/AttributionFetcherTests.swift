//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionFetcherTests.swift
//
//  Created by Nacho Soto on 12/15/22.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class AttributionFetcherTests: TestCase {

    private var systemInfo: MockSystemInfo!
    private var attributionFetcher: AttributionFetcher!

    override func setUp() {
        super.setUp()

        self.systemInfo = MockSystemInfo(finishTransactions: false)
        self.attributionFetcher = .init(attributionFactory: .init(),
                                        systemInfo: self.systemInfo)
    }

    #if canImport(AdServices)
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testAdServicesTokenIfAvailable() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        // Can't guarantee that this will produce a value in tests
        // but at least we ensure that it doesn't hang.
        // See https://github.com/RevenueCat/purchases-ios/issues/2121
        _ = self.attributionFetcher.adServicesToken
    }
    #else
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testAdServicesTokenNilIfNotAvailable() throws {
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()

        expect(self.attributionFetcher.adServicesToken).to(beNil())
    }
    #endif

}
