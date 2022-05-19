//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2StorefrontListenerTests.swift
//
//  Created by Juanpe Catalán on 9/5/22.

import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2StorefrontListenerTests: TestCase {

    private var listener: StoreKit2StorefrontListener! = nil

    override func setUp() {
        super.setUp()

        self.listener = .init(delegate: nil)
    }

    func testStopsListeningToChangesWhenListenerIsReleased() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var handle: Task<Void, Never>?

        expect(self.listener.taskHandle).to(beNil())

        self.listener!.listenForStorefrontChanges()
        handle = self.listener!.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener = nil
        expect(handle?.isCancelled) == true
    }

    func testStopsPreviousTaskWhenStartListeningChangesMoreThanOneTime() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        var handle: Task<Void, Never>?

        expect(self.listener.taskHandle).to(beNil())

        self.listener!.listenForStorefrontChanges()
        handle = self.listener!.taskHandle

        expect(handle).toNot(beNil())
        expect(handle?.isCancelled) == false

        self.listener.listenForStorefrontChanges()
        expect(handle?.isCancelled) == true
    }

}
