//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OperationDispatcherTests.swift
//
//  Created by Nacho Soto on 9/7/23.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class OperationDispatcherTests: TestCase {

    func testDelayForBackgroundedApp() {
        expect(Delay.default(forBackgroundedApp: true)) == .default
    }

    func testDelayForForegroundedApp() {
        expect(Delay.default(forBackgroundedApp: false)) == Delay.none
    }

}
