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
    private static let tokenID = "ept13dcbc01adaa44db9b1691a6be2f9929"
    private static let operationSessionID = "op_session_id"
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

    func testGetHostedCheckoutStatusRunsOnDedicatedLaneNotSharedClient() {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()
        self.httpClient.disableSnapshotTesting()

        let backend = self.makeBackend(checkoutClient: laneClient)
        let statusPath = HTTPRequest.WebBillingPath.getHostedCheckoutStatus(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.userID
        )

        laneClient.mock(
            requestPath: statusPath,
            response: .init(statusCode: .success, response: Self.hostedCheckoutStatusResponse)
        )

        waitUntil { completed in
            backend.webBilling.getHostedCheckoutStatus(
                appUserID: Self.userID,
                operationSessionID: Self.operationSessionID,
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

    /// On the checkout lane, `postHostedCheckout` does not reach the network until
    /// `postExternalPurchaseToken` has fully completed.
    func testHostedCheckoutWaitsForExternalPurchaseTokenRequest() {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()
        self.httpClient.disableSnapshotTesting()

        let backend = self.makeBackend(checkoutClient: laneClient)

        let externalPurchaseTokenPath = HTTPRequest.Path.postExternalPurchaseToken.relativePath
        let hostedCheckoutPath = HTTPRequest.WebBillingPath.postHostedCheckout.relativePath

        laneClient.mock(
            requestPath: .postExternalPurchaseToken,
            response: .init(statusCode: .success,
                            response: Self.externalPurchaseTokenResponse,
                            delay: .seconds(1))
        )
        laneClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.hostedCheckoutResponse)
        )

        let tokenResult: Atomic<Result<ExternalPurchaseTokenResponse, BackendError>?> = nil
        let checkoutResult: Atomic<Result<HostedCheckoutResponse, BackendError>?> = nil
        let callsAtTokenCompletion: Atomic<[String]?> = nil

        backend.externalPurchaseTokenAPI.postExternalPurchaseToken(
            appUserID: Self.userID,
            purchaseType: .linkOut,
            token: "storekit-token"
        ) { result in
            // The operation invokes this closure before calling its internal completion, which is
            // what frees the lane's single queue slot, so hosted checkout cannot have started yet.
            callsAtTokenCompletion.value = laneClient.calls.map(\.request.path.relativePath)
            tokenResult.value = result
        }

        backend.webBilling.postHostedCheckout(
            appUserID: Self.userID,
            packageID: Self.packageID,
            presentedOfferingContext: .init(offeringIdentifier: Self.offeringID),
            paywall: nil,
            externalPurchaseTokenID: Self.tokenID
        ) { checkoutResult.value = $0 }

        expect(tokenResult.value).toEventuallyNot(beNil(), timeout: .seconds(5))
        expect(checkoutResult.value).toEventuallyNot(beNil(), timeout: .seconds(5))

        expect(callsAtTokenCompletion.value) == [externalPurchaseTokenPath]

        expect(laneClient.calls.map(\.request.path.relativePath)) == [
            externalPurchaseTokenPath,
            hostedCheckoutPath
        ]
        expect(tokenResult.value).to(beSuccess())
        expect(checkoutResult.value).to(beSuccess())
        expect(self.httpClient.calls).to(beEmpty())
    }

}

private extension BackendCheckoutLaneTests {

    static let hostedCheckoutResponse: [String: Any] = [
        "operation_session_id": "op_session_id",
        "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_123",
        "success_url": "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=success",
        "cancel_url": "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=cancel"
    ]

    static let hostedCheckoutStatusResponse: [String: Any] = [
        "status": "started",
        "is_expired": false
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

/// Proves the production `Backend` convenience initializer wires checkout onto its own lane: both
/// checkout tap-path requests complete while `/offerings` hangs on the shared client.
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

    func testProductionBackendGivesCheckoutItsOwnLane() throws {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let backend = Backend(
            systemInfo: systemInfo,
            httpClientTimeout: .custom(30),
            eTagManager: MockETagManager(),
            tokenManager: MockTokenManager(),
            operationDispatcher: OperationDispatcher(),
            attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                   systemInfo: systemInfo),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .custom(30))
        )

        let hostedCheckoutPath = HTTPRequest.WebBillingPath.postHostedCheckout.relativePath
        let externalPurchaseTokenPath = HTTPRequest.Path.postExternalPurchaseToken.relativePath
        let offeringsDispatched: Atomic<Bool> = false
        let offeringsCompleted: Atomic<Bool> = false

        stub(condition: pathEndsWith("/offerings")) { _ in
            offeringsDispatched.value = true
            return HTTPStubsResponse(data: Data("{}".utf8), statusCode: 200, headers: nil)
                .responseTime(10)
        }
        stub(condition: pathEndsWith(externalPurchaseTokenPath)) { _ in
            return HTTPStubsResponse(data: Self.externalPurchaseTokenResponseData, statusCode: 200, headers: nil)
        }
        stub(condition: pathEndsWith(hostedCheckoutPath)) { _ in
            return HTTPStubsResponse(data: Self.hostedCheckoutResponseData, statusCode: 200, headers: nil)
        }

        backend.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in
            offeringsCompleted.value = true
        }

        let tokenResult: Result<ExternalPurchaseTokenResponse, BackendError>? = waitUntilValue(
            timeout: .seconds(5)
        ) { completed in
            backend.externalPurchaseTokenAPI.postExternalPurchaseToken(
                appUserID: Self.userID,
                purchaseType: .linkOut,
                token: "storekit-token",
                completion: completed
            )
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

        expect(tokenResult).to(beSuccess())
        expect(checkoutResult).to(beSuccess())
        expect(offeringsDispatched.value).toEventually(beTrue())
        expect(offeringsCompleted.value) == false
    }

    func testConcurrent401sAcrossLanesTriggerExactlyOneTokenRefresh() throws {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let tokenManager = MockTokenManager(enabled: true)
        tokenManager.stubbedCurrentRefreshToken = "refresh-token"
        tokenManager.stubbedCurrentAccessToken = "stale-access-token"

        let backend = Backend(
            systemInfo: systemInfo,
            httpClientTimeout: .custom(30),
            eTagManager: MockETagManager(),
            tokenManager: tokenManager,
            operationDispatcher: OperationDispatcher(),
            attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                   systemInfo: systemInfo),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .custom(30))
        )

        let offeringsHits: Atomic<Int> = .init(0)
        let hostedCheckoutHits: Atomic<Int> = .init(0)
        let tokenRefreshHits: Atomic<Int> = .init(0)
        let hostedCheckoutPath = HTTPRequest.WebBillingPath.postHostedCheckout.relativePath

        stub(condition: pathEndsWith("/offerings")) { _ in
            let hitCount = offeringsHits.increment()
            if hitCount == 1 {
                return HTTPStubsResponse(data: Data(), statusCode: 401, headers: nil)
            }
            return HTTPStubsResponse(data: Self.noOfferingsResponseData, statusCode: 200, headers: nil)
        }
        stub(condition: pathEndsWith(hostedCheckoutPath)) { _ in
            let hitCount = hostedCheckoutHits.increment()
            if hitCount == 1 {
                return HTTPStubsResponse(data: Data(), statusCode: 401, headers: nil)
            }
            return HTTPStubsResponse(data: Self.hostedCheckoutResponseData, statusCode: 200, headers: nil)
        }
        stub(condition: pathEndsWith("/auth/token")) { _ in
            tokenRefreshHits.increment()
            return HTTPStubsResponse(data: Self.tokenRefreshResponseData, statusCode: 200, headers: nil)
                .responseTime(1)
        }

        let offeringsResult: Atomic<Result<OfferingsFetchResult, BackendError>?> = nil
        let checkoutResult: Atomic<Result<HostedCheckoutResponse, BackendError>?> = nil

        backend.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { result in
            offeringsResult.value = result
        }
        backend.webBilling.postHostedCheckout(
            appUserID: Self.userID,
            packageID: Self.packageID,
            presentedOfferingContext: .init(offeringIdentifier: "default"),
            paywall: nil,
            externalPurchaseTokenID: nil
        ) { result in
            checkoutResult.value = result
        }

        expect(offeringsResult.value).toEventuallyNot(beNil(), timeout: .seconds(10))
        expect(checkoutResult.value).toEventuallyNot(beNil(), timeout: .seconds(10))

        expect(tokenRefreshHits.value) == 1
        expect(offeringsHits.value) == 2
        expect(hostedCheckoutHits.value) == 2
        expect(offeringsResult.value).to(beSuccess())
        expect(checkoutResult.value).to(beSuccess())
    }

}

private extension BackendCheckoutLaneParallelTests {

    static let externalPurchaseTokenResponseData = Data("""
    {"external_purchase_id":"b2158121-7af9-49d4-9561-1f14c46b3bc1",\
    "id":"ept13dcbc01adaa44db9b1691a6be2f9929",\
    "is_sandbox":false,"purchase_type":"LINK_OUT","token_source":"APPLE_SDK"}
    """.utf8)

    static let noOfferingsResponseData = Data("{\"offerings\":[],\"current_offering_id\":null}".utf8)

    static let hostedCheckoutResponseData = Data("""
    {"operation_session_id":"op_session_id",\
    "checkout_url":"https://checkout.stripe.com/c/pay/cs_test_123",\
    "success_url":"https://example.com/success",\
    "cancel_url":"https://example.com/cancel"}
    """.utf8)

    static let tokenRefreshResponseData = Data("""
    {"access_token":"new-access-token","id_token":"new-id-token",\
    "refresh_token":"new-refresh-token","scope":"openid","expires_in":3600}
    """.utf8)

}
