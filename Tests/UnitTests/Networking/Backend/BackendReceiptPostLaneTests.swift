//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendReceiptPostLaneTests.swift
//
//  Verifies `POST /receipts` runs on its own dedicated HTTPClient lane when the app configured
//  `UnsyncedTransactionsWaitPolicy.doNotWait`, so it doesn't serialize ahead of other requests.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendReceiptPostLaneTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testReceiptPostRunsOnDedicatedLaneNotSharedClient() {
        let laneClient = self.createReceiptPostLane()

        laneClient.mock(requestPath: .postReceiptData,
                        response: .init(statusCode: .success, response: Self.validCustomerResponse))

        waitUntil { completed in
            self.postReceipt { _ in completed() }
        }

        expect(laneClient.calls).to(haveCount(1))
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testReceiptPostUsesSharedClientWhenNoLaneProvided() {
        self.httpClient.disableSnapshotTesting()
        self.httpClient.mock(requestPath: .postReceiptData,
                             response: .init(statusCode: .success, response: Self.validCustomerResponse))

        waitUntil { completed in
            self.postReceipt { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testCustomerInfoRequestStaysOnSharedClientWhenReceiptPostsHaveALane() {
        let laneClient = self.createReceiptPostLane()

        self.httpClient.mock(requestPath: .getCustomerInfo(appUserID: Self.userID),
                             response: .init(statusCode: .success, response: Self.validCustomerResponse))

        waitUntil { completed in
            self.backend.getCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false) { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(laneClient.calls).to(beEmpty())
    }

}

private extension BackendReceiptPostLaneTests {

    /// Rebuilds the dependencies with a dedicated receipt post lane, returning its client.
    func createReceiptPostLane() -> MockHTTPClient {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()

        self.createDependencies(unsyncedTransactionsWaitPolicy: .doNotWait,
                                receiptPostLaneClient: laneClient)
        self.httpClient.disableSnapshotTesting()

        return laneClient
    }

}
