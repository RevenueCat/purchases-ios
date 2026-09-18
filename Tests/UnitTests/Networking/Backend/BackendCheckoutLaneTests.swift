//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendCheckoutLaneTests.swift
//
//  Verifies checkout tap-path requests run on their own dedicated HTTPClient lane
//  instead of the shared client, so token registration and hosted-checkout creation
//  do not serialize behind other backend requests.

import Foundation
import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

final class BackendCheckoutLaneTests: BaseBackendTests {

    private static let packageID = "$rc_monthly"
    private static let offeringID = "default"
    private static let productIds: Set<String> = ["test_monthly"]

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostHostedCheckoutRunsOnDedicatedLaneNotSharedClient() {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()
        self.httpClient.disableSnapshotTesting()

        let backend = self.makeBackend(checkoutClient: laneClient)

        laneClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.hostedCheckoutResponse)
        )

        waitUntil { completed in
            backend.webBilling.postHostedCheckout(
                appUserID: Self.userID,
                packageID: Self.packageID,
                presentedOfferingContext: .init(offeringIdentifier: Self.offeringID),
                paywall: nil,
                externalPurchaseTokenID: nil,
                completion: { _ in completed() }
            )
        }

        expect(laneClient.calls).to(haveCount(1))
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testPostExternalPurchaseTokenRunsOnDedicatedLaneNotSharedClient() {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()
        self.httpClient.disableSnapshotTesting()

        let backend = self.makeBackend(checkoutClient: laneClient)

        laneClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.externalPurchaseTokenResponse)
        )

        waitUntil { completed in
            backend.externalPurchaseTokenAPI.postExternalPurchaseToken(
                appUserID: Self.userID,
                purchaseType: .linkOut,
                token: "storekit-token",
                completion: { _ in completed() }
            )
        }

        expect(laneClient.calls).to(haveCount(1))
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetWebBillingProductsStillRunsOnSharedClient() {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()
        self.httpClient.disableSnapshotTesting()

        let backend = self.makeBackend(checkoutClient: laneClient)

        self.httpClient.mock(
            requestPath: .getWebBillingProducts(userId: Self.userID, productIds: Self.productIds),
            response: .init(statusCode: .success, response: Self.noProductsResponse)
        )

        waitUntil { completed in
            backend.webBilling.getWebBillingProducts(
                appUserID: Self.userID,
                productIds: Self.productIds,
                completion: { _ in completed() }
            )
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(laneClient.calls).to(beEmpty())
    }

    func testCheckoutRequestsFallBackToSharedClientWhenNoLaneProvided() {
        self.httpClient.disableSnapshotTesting()

        let backend = Backend(
            backendConfig: self.makeConfig(client: self.httpClient,
                                           queue: Backend.QueueProvider.createQueue(for: .default)),
            attributionFetcher: self.makeAttributionFetcher()
        )

        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.hostedCheckoutResponse)
        )
        self.httpClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success, response: Self.externalPurchaseTokenResponse)
        )

        waitUntil { completed in
            backend.webBilling.postHostedCheckout(
                appUserID: Self.userID,
                packageID: Self.packageID,
                presentedOfferingContext: .init(offeringIdentifier: Self.offeringID),
                paywall: nil,
                externalPurchaseTokenID: nil,
                completion: { _ in completed() }
            )
        }

        waitUntil { completed in
            backend.externalPurchaseTokenAPI.postExternalPurchaseToken(
                appUserID: Self.userID,
                purchaseType: .linkOut,
                token: "storekit-token",
                completion: { _ in completed() }
            )
        }

        expect(self.httpClient.calls).to(haveCount(2))
    }

}

private extension BackendCheckoutLaneTests {

    static let hostedCheckoutResponse: [String: Any] = [
        "operation_session_id": "op_session_id",
        "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_123",
        "success_url": "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=success",
        "cancel_url": "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=cancel"
    ]

    static let externalPurchaseTokenResponse: [String: Any] = [
        "external_purchase_id": "b2158121-7af9-49d4-9561-1f14c46b3bc1",
        "id": "ept13dcbc01adaa44db9b1691a6be2f9929",
        "is_sandbox": false,
        "purchase_type": "LINK_OUT",
        "token_source": "APPLE_SDK"
    ]

    static let noProductsResponse: [String: Any?] = [
        "product_details": [] as [[String: Any]]
    ]

    func makeBackend(checkoutClient: MockHTTPClient) -> Backend {
        let lanes = BackendLanes(
            defaultConfiguration: self.makeConfig(client: self.httpClient,
                                                  queue: Backend.QueueProvider.createQueue(for: .default)),
            dedicatedConfigurations: [
                .checkout: self.makeConfig(
                    client: checkoutClient,
                    queue: Backend.QueueProvider.createQueue(for: .checkout)
                )
            ]
        )
        return Backend(lanes: lanes, attributionFetcher: self.makeAttributionFetcher())
    }

    func makeConfig(client: MockHTTPClient, queue: OperationQueue) -> BackendConfiguration {
        return BackendConfiguration(
            httpClient: client,
            operationDispatcher: self.operationDispatcher,
            operationQueue: queue,
            diagnosticsQueue: Backend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: self.systemInfo,
            offlineCustomerInfoCreator: self.mockOfflineCustomerInfoCreator,
            dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate)
        )
    }

    func makeAttributionFetcher() -> AttributionFetcher {
        return AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                  systemInfo: self.systemInfo)
    }

}

/// Proves the dedicated lane actually runs hosted checkout in parallel with `/offerings`, using real
/// `HTTPClient`s (each serial internally) and a stubbed transport: a hung `/offerings` on the
/// shared client must not block hosted checkout on the lane.
final class BackendCheckoutLaneParallelTests: TestCase {

    private static let userID = "lane-user"
    private static let packageID = "$rc_monthly"

    override func setUpWithError() throws {
        try super.setUpWithError()

        #if os(watchOS)
        // See https://github.com/AliSoftware/OHHTTPStubs/issues/287
        try XCTSkipIf(true, "OHHTTPStubs does not currently support watchOS")
        #endif
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testHostedCheckoutCompletesWhileOfferingsHangsOnSeparateLane() throws {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let eTagManager = MockETagManager()
        let tokenManager = MockTokenManager()

        func makeClient() -> HTTPClient {
            return HTTPClient(systemInfo: systemInfo,
                              eTagManager: eTagManager,
                              tokenManager: tokenManager,
                              signing: MockSigning(),
                              diagnosticsTracker: nil,
                              networkTimeout: .custom(30),
                              operationDispatcher: OperationDispatcher(),
                              apiSourceFailover: nil,
                              timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .custom(30)))
        }

        func makeConfig(_ client: HTTPClient, _ queue: OperationQueue) -> BackendConfiguration {
            return BackendConfiguration(httpClient: client,
                                        operationDispatcher: OperationDispatcher(),
                                        operationQueue: queue,
                                        diagnosticsQueue: Backend.QueueProvider.createDiagnosticsQueue(),
                                        systemInfo: systemInfo,
                                        offlineCustomerInfoCreator: nil,
                                        dateProvider: DateProvider())
        }

        let lanes = BackendLanes(
            defaultConfiguration: makeConfig(makeClient(), Backend.QueueProvider.createQueue(for: .default)),
            dedicatedConfigurations: [
                .checkout: makeConfig(makeClient(), Backend.QueueProvider.createQueue(for: .checkout))
            ]
        )
        let backend = Backend(lanes: lanes,
                              attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                                     systemInfo: systemInfo))

        let hostedCheckoutPath = HTTPRequest.WebBillingPath.postHostedCheckout.relativePath
        let offeringsDispatched: Atomic<Bool> = false
        let offeringsCompleted: Atomic<Bool> = false

        stub(condition: pathEndsWith("/offerings")) { _ in
            offeringsDispatched.value = true
            return HTTPStubsResponse(data: Data("{}".utf8), statusCode: 200, headers: nil)
                .responseTime(10)
        }
        stub(condition: pathEndsWith(hostedCheckoutPath)) { _ in
            return HTTPStubsResponse(
                data: Data("""
                {"operation_session_id":"op_session_id",\
                "checkout_url":"https://checkout.stripe.com/c/pay/cs_test_123",\
                "success_url":"https://example.com/success",\
                "cancel_url":"https://example.com/cancel"}
                """.utf8),
                statusCode: 200,
                headers: nil
            )
        }

        backend.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in
            offeringsCompleted.value = true
        }

        let checkoutResult: Result<HostedCheckoutResponse, BackendError>? = waitUntilValue(
            timeout: .seconds(5)
        ) { completed in
            backend.webBilling.postHostedCheckout(
                appUserID: Self.userID,
                packageID: Self.packageID,
                presentedOfferingContext: .init(offeringIdentifier: "default"),
                paywall: nil,
                externalPurchaseTokenID: nil,
                completion: completed
            )
        }

        expect(checkoutResult).to(beSuccess())
        expect(offeringsDispatched.value).toEventually(beTrue())
        expect(offeringsCompleted.value) == false
    }

}
