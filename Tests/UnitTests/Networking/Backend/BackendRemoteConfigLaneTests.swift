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
                request: .init(appUserID: Self.userID),
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
                request: .init(appUserID: Self.userID),
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

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testConfigCompletesWhileOfferingsHangsOnSeparateLane() throws {
        #if os(watchOS)
        throw XCTSkip("OHHTTPStubs does not support watchOS")
        #endif

        let systemInfo = MockSystemInfo(finishTransactions: true)
        let eTagManager = MockETagManager()

        func makeClient() -> HTTPClient {
            return HTTPClient(systemInfo: systemInfo,
                              eTagManager: eTagManager,
                              signing: MockSigning(),
                              diagnosticsTracker: nil,
                              requestTimeout: 30,
                              operationDispatcher: OperationDispatcher())
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
                request: .init(appUserID: Self.userID),
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(configResult).to(beSuccess())
        expect(offeringsDispatched.value).toEventually(beTrue())
        expect(offeringsCompleted.value) == false
    }

}
