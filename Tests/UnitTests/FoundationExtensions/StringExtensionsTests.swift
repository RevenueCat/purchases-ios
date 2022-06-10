//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StringExtensionsTests.swift
//
//  Created by Nacho Soto on 6/10/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class StringExtensionsTests: TestCase {

    func testROT13() {
        let mangledTrackingClassName = "NGGenpxvatZnantre"
        let mangledAuthStatusPropertyName = "genpxvatNhgubevmngvbaFgnghf"

        expect(mangledTrackingClassName.rot13()) == "ATTrackingManager"
        expect(mangledAuthStatusPropertyName.rot13()) == "trackingAuthorizationStatus"
    }

}
