//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MacAppStoreDetectorTests.swift
//
//  Created by Nacho Soto on 1/10/24.

import Nimble
import XCTest

@testable import RevenueCat

#if os(macOS)

class MacAppStoreDetectorTests: TestCase {

    func testIsMacAppStore() {
        expect(DefaultMacAppStoreDetector().isMacAppStore) == false
    }

}

#endif
