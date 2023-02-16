//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OtherIntegrationTests.swift
//
//  Created by Nacho Soto on 10/10/22.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

class OtherIntegrationTests: BaseBackendIntegrationTests {

    func testHealthRequest() async throws {
        try await Purchases.shared.healthRequest(signatureVerification: false)
    }

    func testHealthRequestWithVerification() async throws {
        try await Purchases.shared.healthRequest(signatureVerification: true)
    }

}
