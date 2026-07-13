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
