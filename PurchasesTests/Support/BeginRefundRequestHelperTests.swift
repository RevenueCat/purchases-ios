//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BeginRefundRequestHelperTests.swift
//
//  Created by Madeline Beyl on 10/15/21.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

#if os(macOS) || os(iOS)

class BeginRefundRequestHelperTests: XCTestCase {

    private var systemInfo: MockSystemInfo!
    private var helper: BeginRefundRequestHelper!
    private let mockTransactionId: UInt64 = UInt64()


    override func setUp() {
        systemInfo = try! MockSystemInfo(platformFlavor: "", platformFlavorVersion: "", finishTransactions: true)
        helper = BeginRefundRequestHelper(systemInfo: systemInfo)
    }

