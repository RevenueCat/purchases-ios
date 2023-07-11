//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DebugViewSwiftUITests.swift
//
//  Created by Nacho Soto on 6/12/23.

#if DEBUG && (os(iOS) || VISION_OS) && swift(>=5.8)

import Nimble
@testable import RevenueCat
import SnapshotTesting
import XCTest

import SwiftUI

@MainActor
@available(iOS 16.0, *)
class DebugViewSwiftUITests: TestCase {

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()
    }

    func testLoadingState() {
        expect(self.view(with: .init(), width: 300, height: 400))
            .to(haveValidSnapshot(as: .image))
    }

    func testDebugView() throws {
        let model = DebugViewModel()
        model.configuration = .loaded(.init(
            sdkVersion: "4.20.0",
            observerMode: false,
            sandbox: true,
            storeKit2Enabled: true,
            offlineCustomerInfoSupport: true,
            verificationMode: "Enforced",
            receiptURL: URL(string: "file://receipt")
        ))
        model.diagnosticsResult = .loaded(())
        model.customerInfo = .loaded(try Self.mockCustomerInfo)
        model.currentAppUserID = "Nacho"
        model.offerings = .loaded(.init(
            offerings: [:],
            currentOfferingID: nil,
            response: .mockResponse
        ))

        expect(self.view(with: model, width: 450, height: 900))
            .to(haveValidSnapshot(as: .image))
    }

}

@available(iOS 16.0, *)
private extension DebugViewSwiftUITests {

    func view(
        with model: DebugViewModel,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        NavigationView {
            DebugSummaryView(model: model)
        }
            .frame(width: width, height: height)
    }

    static var mockCustomerInfo: CustomerInfo {
        get throws {
            return try .init(
                data: [
                    "request_date": "2023-08-16T10:30:42Z",
                    "subscriber": [
                        "subscriptions": [
                            "monthly_freetrial": [
                                "billing_issues_detected_at": nil,
                                "expires_date": "2019-07-26T23:50:40Z",
                                "is_sandbox": true,
                                "original_purchase_date": "2019-07-26T23:30:41Z",
                                "period_type": "normal",
                                "purchase_date": "2019-07-26T23:45:40Z",
                                "store": "app_store",
                                "unsubscribe_detected_at": nil
                            ]  as [String: Any?]
                        ],
                        "non_subscriptions": [:]  as [String: Any],
                        "entitlements": [
                            "pro": [
                                "product_identifier": "monthly_freetrial",
                                "expires_date": "2018-12-19T02:40:36Z",
                                "purchase_date": "2018-07-26T23:30:41Z"
                            ]
                        ],
                        "first_seen": "2023-07-17T00:05:54Z",
                        "original_app_user_id": "nacho2",
                        "other_purchases": [:]  as [String: Any]
                    ]  as [String: Any]
                ]
            )
        }
    }

}

#endif
