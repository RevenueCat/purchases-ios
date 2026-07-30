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
        let laneClient = self.createClient(#file)
        let backend = self.makeBackend(receiptPostLaneClient: laneClient)

        laneClient.mock(requestPath: .postReceiptData,
                        response: .init(statusCode: .success, response: Self.validCustomerResponse))

        waitUntil { completed in
            self.postReceipt(to: backend) { _ in completed() }
        }

        expect(laneClient.calls).to(haveCount(1))
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testReceiptPostUsesSharedClientWhenNoLaneProvided() {
        let backend = self.makeBackend(receiptPostLaneClient: nil)

        self.httpClient.mock(requestPath: .postReceiptData,
                             response: .init(statusCode: .success, response: Self.validCustomerResponse))

        waitUntil { completed in
            self.postReceipt(to: backend) { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testCustomerInfoRequestStaysOnSharedClientWhenReceiptPostsHaveALane() {
        let laneClient = self.createClient(#file)
        let backend = self.makeBackend(receiptPostLaneClient: laneClient)

        self.httpClient.mock(requestPath: .getCustomerInfo(appUserID: Self.userID),
                             response: .init(statusCode: .success, response: Self.validCustomerResponse))

        waitUntil { completed in
            backend.getCustomerInfo(appUserID: Self.userID, isAppBackgrounded: false) { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(laneClient.calls).to(beEmpty())
    }

}

private extension BackendReceiptPostLaneTests {

    func makeBackend(receiptPostLaneClient: MockHTTPClient?) -> Backend {
        self.httpClient.disableSnapshotTesting()
        receiptPostLaneClient?.disableSnapshotTesting()

        let lane = receiptPostLaneClient.map {
            BackendConfiguration.Lane(httpClient: $0,
                                      operationQueue: Backend.QueueProvider.createReceiptPostQueue())
        }

        let config = BackendConfiguration(
            httpClient: self.httpClient,
            operationDispatcher: self.operationDispatcher,
            operationQueue: Backend.QueueProvider.createBackendQueue(),
            diagnosticsQueue: Backend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: self.systemInfo,
            offlineCustomerInfoCreator: self.mockOfflineCustomerInfoCreator,
            dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate),
            receiptPostLane: lane
        )

        return Backend(backendConfig: config,
                       attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                              systemInfo: self.systemInfo))
    }

    func postReceipt(to backend: Backend, completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        backend.post(receipt: .receipt("a receipt".asData),
                     productData: nil,
                     transactionData: .init(presentedOfferingContext: nil,
                                            unsyncedAttributes: nil,
                                            storeCountry: nil),
                     postReceiptSource: .init(isRestore: false, initiationSource: .queue),
                     observerMode: false,
                     originalPurchaseCompletedBy: nil,
                     appTransaction: nil,
                     associatedTransactionId: nil,
                     appUserID: Self.userID,
                     containsAttributionData: false,
                     completion: completion)
    }

}
