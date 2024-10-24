//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaymentQueueWrapperTests.swift
//
//  Created by Nacho Soto on 9/30/22.

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PaymentQueueWrapperTests: TestCase {

    private var paymentQueue: MockPaymentQueue!
    private var wrapper: PaymentQueueWrapper!
    private var delegate: WrapperDelegate!

    private lazy var purchaseIntentsAPIAvailable: Bool = {
        // PurchaseIntents was introduced in macOS with macOS 14.4, which was first shipped with Xcode 15.3,
        // which shipped with version 5.10 of the Swift compiler. We need to check for the Swift compiler version
        // because the PurchaseIntents framework isn't available on Xcode versions <15.3.
        #if compiler(>=5.10)
        if #available(iOS 16.4, macOS 14.4, *) {
            return true
        } else {
            return false
        }
        #else
        return false
        #endif
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.paymentQueue = MockPaymentQueue()
        self.wrapper = .init(paymentQueue: self.paymentQueue)
        self.delegate = WrapperDelegate()
    }

    func testNoDelegateIsSetByDefault() {
        expect(self.paymentQueue.delegate).to(beNil())
    }

    func testNoObserverIsAddedByDefault() {
        expect(self.paymentQueue.observers).to(beEmpty())
    }

    func testSettingDelegateSetsPaymentQueueDelegate() {
        self.wrapper.delegate = self.delegate

        expect(self.paymentQueue.delegate) === self.wrapper
    }

    func testSettingDelegateAddsTransactionObserver() {
        self.wrapper.delegate = self.delegate

        if purchaseIntentsAPIAvailable {
            expect(self.paymentQueue.observers).to(haveCount(0))
            expect(self.paymentQueue.observers.onlyElement).to(beNil())
        } else {
            expect(self.paymentQueue.observers).to(haveCount(1))
            expect(self.paymentQueue.observers.onlyElement) === self.wrapper
        }
    }

    func testResettingDelegateClearsPaymentQueueDelegate() {
        self.wrapper.delegate = self.delegate
        self.wrapper.delegate = nil

        expect(self.paymentQueue.delegate).to(beNil())
    }

    func testResettingDelegateRemovesTransactionObserver() {
        self.wrapper.delegate = self.delegate
        self.wrapper.delegate = nil

        expect(self.paymentQueue.observers).to(beEmpty())
    }

}

private final class WrapperDelegate: NSObject, PaymentQueueWrapperDelegate {

    override init() {}

    func paymentQueueWrapper(
        _ wrapper: RevenueCat.PaymentQueueWrapper,
        shouldAddStorePayment payment: SKPayment,
        for product: RevenueCat.SK1Product
    ) -> Bool {
        fail("Unexpected call")
        return false
    }

    var paymentQueueWrapperShouldShowPriceConsent: Bool {
        fail("Unexpected call")
        return false
    }

}
