//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesPaywallEventsTests.swift
//
//  Created by Nacho Soto on 9/8/23.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesPaywallEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testApplicationWillEnterForegroundSendsEvents() async throws {
        self.notificationCenter.fireApplicationWillEnterForegroundNotification()

        let manager = try self.mockEventsManager

        try await asyncWait { await manager.invokedFlushEventsWithBackgroundTask == true }

        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThreadDelayParam) == .long
    }

    func testApplicationWillEnterBackgroundSendsEvents() async throws {
        self.notificationCenter.fireApplicationDidEnterBackgroundNotification()

        let manager = try self.mockEventsManager

        try await asyncWait { await manager.invokedFlushEventsWithBackgroundTask == true }

        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThreadDelayParam) == JitterableDelay.none
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PurchasesPaywallEventsTests {

    typealias LogInResult = Result<(customerInfo: CustomerInfo, created: Bool), PublicError>
    typealias LogOutResult = Result<CustomerInfo, PublicError>

    // swiftlint:disable force_try
    static let mockLoggedInInfo = try! CustomerInfo(data: PurchasesPaywallEventsTests.loggedInCustomerInfoData)
    static let mockLoggedOutInfo = try! CustomerInfo(data: PurchasesPaywallEventsTests.loggedOutCustomerInfoData)
    // swiftlint:enable force_try

    private static let loggedInCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "user",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any]
    ]

    private static let loggedOutCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "$RCAnonymousID:5b6fdbad3a0c4f879e43d269ecdf9ba1",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any]
    ]

    /// Converts the result of `Purchases.logIn` into `LogInResult`
    static func logInResult(_ info: CustomerInfo?, _ created: Bool, _ error: PublicError?) -> LogInResult {
        return .init(info.map { ($0, created) }, error)
    }

}
