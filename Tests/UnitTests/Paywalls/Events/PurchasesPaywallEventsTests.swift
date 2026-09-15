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

@_spi(Internal) @testable import RevenueCat

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

        await expect(manager.invokedFlushAllEventsWithBackgroundTask.value).toEventually(beTrue())

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == .long
    }

    func testCustomerCenterEventsReachManager() async throws {
        self.mockOperationDispatcher.forwardToOriginalDispatchOnWorkerThread = true
        let manager = try self.mockEventsManager
        let creation = CustomerCenterEventCreationData()
        let impression = CustomerCenterEvent.impression(
            creation,
            .init(locale: Locale(identifier: "es_ES"), darkMode: true, isSandbox: true, displayMode: .fullScreen)
        )
        let answer = CustomerCenterAnswerSubmittedEvent.answerSubmitted(
            creation,
            .init(locale: Locale(identifier: "es_ES"), darkMode: true, isSandbox: true,
                  displayMode: .fullScreen, path: .cancel, url: nil, surveyOptionID: "", revisionID: 1)
        )

        self.purchases.track(customerCenterEvent: impression)
        self.purchases.track(customerCenterEvent: answer)

        await expect { await manager.trackedEvents.count }.toEventually(equal(2))
        let events = await manager.trackedEvents
        expect(events.compactMap { $0 as? CustomerCenterEvent }) == [impression]
        expect(events.compactMap { $0 as? CustomerCenterAnswerSubmittedEvent }) == [answer]
    }

    func testCustomerCenterEventPreservesCallerPriority() async throws {
        self.mockOperationDispatcher.forwardToOriginalDispatchOnWorkerThread = true
        let manager = try self.mockEventsManager
        let purchases = try XCTUnwrap(self.purchases)
        let event = CustomerCenterEvent.impression(
            .init(),
            .init(locale: .current, darkMode: false, isSandbox: true, displayMode: .fullScreen)
        )

        await Task(priority: .userInitiated) {
            purchases.track(customerCenterEvent: event)
        }.value

        await expect { await manager.trackedEvents.count }.toEventually(equal(1))
        let priorities = await manager.trackedEventPriorities
        expect(priorities) == [.userInitiated]
    }

    func testApplicationWillResignActiveSendsEvents() async throws {
        self.notificationCenter.fireApplicationWillResignActiveNotification()

        let manager = try self.mockEventsManager

        /// There are other methods (e.g. health check) that also dispatch async on worker thread,
        /// so we reset the flag here to make sure we check that no new invocations happened.
        self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread = false
        await expect(manager.invokedFlushAllEventsWithBackgroundTask.value).toEventually(beTrue())

        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnWorkerThread) == false
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
