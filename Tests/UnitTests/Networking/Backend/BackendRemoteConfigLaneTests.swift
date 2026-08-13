//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendRemoteConfigLaneTests.swift
//
//  Verifies the remote-config request runs on its own dedicated HTTPClient lane
//  instead of the shared client, so `/config` does not serialize behind other
//  backend requests.

import Foundation
import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

final class BackendRemoteConfigLaneTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testRemoteConfigRequestRunsOnDedicatedLaneNotSharedClient() {
        let laneClient = self.createClient(#file)
        laneClient.disableSnapshotTesting()
        self.httpClient.disableSnapshotTesting()

        let backend = Backend(
            backendConfig: self.makeConfig(client: self.httpClient,
                                           queue: Backend.QueueProvider.createBackendQueue()),
            remoteConfigBackendConfig: self.makeConfig(client: laneClient,
                                                       queue: Backend.QueueProvider.createRemoteConfigQueue()),
            attributionFetcher: self.makeAttributionFetcher()
        )

        laneClient.mock(
            requestPath: HTTPRequest.Path.remoteConfig(domain: "app"),
            response: .init(statusCode: .noContent, body: Data(), verificationResult: .verified)
        )

        waitUntil { completed in
            backend.remoteConfigAPI.getRemoteConfig(
                request: .init(fetchContext: .appStart, appUserID: Self.userID),
                isAppBackgrounded: false
            ) { _ in completed() }
        }

        expect(laneClient.calls).to(haveCount(1))
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testRemoteConfigFallsBackToSharedClientWhenNoLaneProvided() {
        self.httpClient.disableSnapshotTesting()

        let backend = Backend(
            backendConfig: self.makeConfig(client: self.httpClient,
                                           queue: Backend.QueueProvider.createBackendQueue()),
            attributionFetcher: self.makeAttributionFetcher()
        )

        self.httpClient.mock(
            requestPath: HTTPRequest.Path.remoteConfig(domain: "app"),
            response: .init(statusCode: .noContent, body: Data(), verificationResult: .verified)
        )

        waitUntil { completed in
            backend.remoteConfigAPI.getRemoteConfig(
                request: .init(fetchContext: .appStart, appUserID: Self.userID),
                isAppBackgrounded: false
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(1))
    }

}

private extension BackendRemoteConfigLaneTests {

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

/// Proves the dedicated lane actually runs `/config` in parallel with `/offerings`, using real
/// `HTTPClient`s (each serial internally) and a stubbed transport: a hung `/offerings` on the
/// shared client must not block `/config` on the lane.
final class BackendRemoteConfigLaneParallelTests: TestCase {

    private static let userID = "lane-user"

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

    func testConfigCompletesWhileOfferingsHangsOnSeparateLane() throws {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let eTagManager = MockETagManager()

        func makeClient() -> HTTPClient {
            return HTTPClient(systemInfo: systemInfo,
                              eTagManager: eTagManager,
                              tokenManager: MockTokenManager(),
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

        let backend = Backend(
            backendConfig: makeConfig(makeClient(), Backend.QueueProvider.createBackendQueue()),
            remoteConfigBackendConfig: makeConfig(makeClient(), Backend.QueueProvider.createRemoteConfigQueue()),
            attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                   systemInfo: systemInfo)
        )

        // `/offerings` stays in flight for the whole test; `/config` returns immediately. If config
        // shared the offerings client, it would queue behind the hung `/offerings` and time out.
        let offeringsDispatched: Atomic<Bool> = false
        let offeringsCompleted: Atomic<Bool> = false

        stub(condition: pathEndsWith("/offerings")) { _ in
            offeringsDispatched.value = true
            return HTTPStubsResponse(data: Data("{}".utf8), statusCode: 200, headers: nil)
                .responseTime(10)
        }
        stub(condition: pathEndsWith("/config/app")) { _ in
            return HTTPStubsResponse(data: Data(), statusCode: 204, headers: nil)
        }

        backend.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in
            offeringsCompleted.value = true
        }

        let configResult: Result<RemoteConfigFetchResult, BackendError>? = waitUntilValue(
            timeout: .seconds(5)
        ) { completed in
            backend.remoteConfigAPI.getRemoteConfig(
                request: .init(fetchContext: .appStart, appUserID: Self.userID),
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(configResult).to(beSuccess())
        expect(offeringsDispatched.value).toEventually(beTrue())
        expect(offeringsCompleted.value) == false
    }

    /// Both lanes talk to the same hosts, so a timeout either of them sees must fast-fail the other.
    func testTimeoutOnMainLaneReducesTimeoutOnRemoteConfigLane() throws {
        let systemInfo = MockSystemInfo(
            finishTransactions: true,
            dangerousSettings: DangerousSettings(
                autoSyncPurchases: true,
                internalSettings: DangerousSettings.Internal(usesRemoteConfigAPISources: true)
            )
        )
        let backend = Backend(
            systemInfo: systemInfo,
            httpClientTimeout: .default,
            eTagManager: MockETagManager(),
            tokenManager: MockTokenManager(),
            operationDispatcher: OperationDispatcher(),
            attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                   systemInfo: systemInfo),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default)
        )

        let apiHost = try XCTUnwrap(SystemInfo.apiBaseURL.host)
        stub(condition: pathEndsWith("/offerings")) { request in
            if request.url?.host == apiHost {
                return .timeoutResponse()
            }
            return HTTPStubsResponse(data: Data(), statusCode: 400, headers: nil)
        }

        waitUntil { completed in
            backend.offerings.getOfferings(appUserID: Self.userID, isAppBackgrounded: false) { _ in
                completed()
            }
        }

        let remoteConfigTimeout: Atomic<TimeInterval?> = nil
        stub(condition: pathEndsWith("/config/app")) { request in
            remoteConfigTimeout.value = request.timeoutInterval
            return HTTPStubsResponse(data: Data(), statusCode: 204, headers: nil)
        }

        let configResult: Result<RemoteConfigFetchResult, BackendError>? = waitUntilValue { completed in
            backend.remoteConfigAPI.getRemoteConfig(
                request: .init(fetchContext: .appStart, appUserID: Self.userID),
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(configResult).to(beSuccess())
        expect(remoteConfigTimeout.value) == HTTPRequestTimeoutManager.Timeout.mainSourceNoFallbackReduced
    }

}
