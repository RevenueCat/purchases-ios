//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreMessageTypeTests.swift
//
//  Created by Antonio Rico Diez on 3/10/23.

import Foundation
import Nimble
import StoreKit

@testable import RevenueCat

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

@available(iOS 16.0, *)
class StoreMessagesTypeTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    func testMessageReasonIsMappedToCorrectStoreMessageType() async throws {
        #if swift(>=5.8)
        if #available(iOS 16.4, *) {
            expect(Message.Reason.billingIssue.messageType) == .billingIssue
        }
        #endif
        expect(Message.Reason.priceIncreaseConsent.messageType) == .priceIncreaseConsent
        expect(Message.Reason.generic.messageType) == .generic
    }
}

#endif
