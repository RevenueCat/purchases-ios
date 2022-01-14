//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionListenerTests.swift
//
//  Created by Nacho Soto on 1/14/22.

import Nimble
@testable import RevenueCat
import StoreKitTest
import XCTest

class StoreKit2TransactionListenerTests: StoreKitConfigTestCase {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testStopsListeningToTransactions() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var listener: StoreKit2TransactionListener? = .init(delegate: nil)
        var handle: Task<Void, Never>?

        expect(listener!.taskHandle).to(beNil())

        listener!.listenForTransactions()
        handle = listener!.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        listener = nil
        expect(handle?.isCancelled) == true
    }

}
