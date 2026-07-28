//
//  BackendAPISourceFailoverIntegrationTests.swift
//  RevenueCat
//
//  Created by Toni Rico on 27/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

/// End-to-end coverage of API source failover through a real `Backend.getCustomerInfo` request: the
/// production wiring built by the `Backend` convenience init (real `HTTPClient`s, one shared
/// `APISourceFailover`, real `SourceHealthChecker` whose probes go over the URL loading system) and a
/// real `RemoteConfigSourceProvider` fed by an in-memory `sources` topic. OHHTTPStubs stands in for
/// the source hosts, routing each host's API endpoint and its `/v1/health/connectivity` endpoint by
/// path and recording the exact request order, mirroring purchases-android's
/// `BackendAPISourceFailoverIntegrationTest`.
final class BackendAPISourceFailoverIntegrationTests: TestCase {

    private static let appUserID = "integration-test-user"
    private static let customerInfoPath = "/v1/subscribers/integration-test-user"
    private static let healthPath = "/v1/health/connectivity"

    private static let sourceAHost = "source-a.rc-test.com"
    private static let sourceBHost = "source-b.rc-test.com"

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

    func testGetCustomerInfoSucceedsOnThePrimarySourceWithoutHealthChecks() {
        let sourceA = self.stubSource(host: Self.sourceAHost, endpoint: Self.customerInfoResponse)
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beSuccess())
        expect(sourceA.value) == [Self.customerInfoPath]
        expect(sourceB.value).to(beEmpty())
    }

    func testGetCustomerInfoSurfacesA5xxWithoutFailingOverWhenTheSourceIsHealthy() {
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: { Self.response(500) },
                                      health: { Self.response(200) })
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beFailure())
        expect(self.isServerError(result)) == true
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value).to(beEmpty())
    }

    func testGetCustomerInfoFailsOverOnA5xxWhenTheSourceIsUnhealthyAndStaysFailedOver() {
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: { Self.response(500) },
                                      health: { Self.response(503) })
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beSuccess())
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value) == [Self.customerInfoPath]

        // The provider advanced, so a subsequent request goes straight to the second source.
        let secondResult = self.fetchCustomerInfo(backend)

        expect(secondResult).to(beSuccess())
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value) == [Self.customerInfoPath, Self.customerInfoPath]
    }

    func testGetCustomerInfoFailsOverWhenTheSourceIsUnreachable() {
        // Both the API request and the health probe fail at the connection level, like a host whose
        // port refuses connections.
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: Self.connectionRefused,
                                      health: Self.connectionRefused)
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beSuccess())
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value) == [Self.customerInfoPath]
    }

    func testGetCustomerInfoSurfacesAConnectionErrorWithoutFailingOverWhenTheSourceIsHealthy() {
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: Self.connectionRefused,
                                      health: { Self.response(200) })
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beFailure())
        expect(self.isServerError(result)) == false
        // The health check ran and passed, and we still never failed over to the second source.
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value).to(beEmpty())
    }

    func testGetCustomerInfoSurfacesTheErrorOnceEverySourceIsUnhealthy() {
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: { Self.response(500) },
                                      health: { Self.response(503) })
        let sourceB = self.stubSource(host: Self.sourceBHost,
                                      endpoint: { Self.response(500) },
                                      health: { Self.response(503) })
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beFailure())
        expect(self.isServerError(result)) == true
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value) == [Self.customerInfoPath, Self.healthPath]
    }

    func testGetCustomerInfoDoesNotFailOverOrHealthCheckOnA4xx() {
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: { Self.response(404) },
                                      health: { Self.response(200) })
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beFailure())
        expect(self.isServerError(result)) == false
        expect(sourceA.value) == [Self.customerInfoPath]
        expect(sourceB.value).to(beEmpty())
    }

    func testGetCustomerInfoDoesNotFailOverOrHealthCheckOnADeviceConnectivityError() {
        // iOS-specific behavior with no Android counterpart: the device being offline is
        // distinguishable from a host outage, so the SDK fails directly without probing the source.
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: { HTTPStubsResponse(error: URLError(.notConnectedToInternet)) },
                                      health: { Self.response(200) })
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beFailure())
        expect(sourceA.value) == [Self.customerInfoPath]
        expect(sourceB.value).to(beEmpty())
    }

    func testGetCustomerInfoIgnoresSourcesWhenTheDangerousSettingIsDisabled() {
        let sourceA = self.stubSource(host: Self.sourceAHost, endpoint: Self.customerInfoResponse)
        let sourceB = self.stubSource(host: Self.sourceBHost, endpoint: Self.customerInfoResponse)
        let defaultHost = self.stubSource(host: "api.revenuecat.com", endpoint: Self.customerInfoResponse)
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost],
                                         usesRemoteConfigAPISources: false)

        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beSuccess())
        expect(defaultHost.value) == [Self.customerInfoPath]
        expect(sourceA.value).to(beEmpty())
        expect(sourceB.value).to(beEmpty())
    }

    func testBothHTTPClientLanesShareTheSameFailover() {
        // Backend builds one APISourceFailover for both the main HTTPClient and the dedicated
        // remote-config lane: a failover triggered by one lane must advance the source list (and
        // reuse the health-check verdict) for the other.
        let sourceA = self.stubSource(host: Self.sourceAHost,
                                      endpoint: { Self.response(500) },
                                      health: { Self.response(503) })
        let sourceB: Atomic<[String]> = .init([])
        stub(condition: isHost(Self.sourceBHost)) { request in
            let path = request.url?.path ?? ""
            sourceB.modify { $0.append(path) }
            if path.hasPrefix("/v1/config") {
                return HTTPStubsResponse(data: Data(), statusCode: 204, headers: nil)
            }
            return Self.customerInfoResponse()
        }
        let backend = Self.createBackend(sources: [Self.sourceAHost, Self.sourceBHost])

        // The main lane fails over A -> B.
        let result = self.fetchCustomerInfo(backend)

        expect(result).to(beSuccess())
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value) == [Self.customerInfoPath]

        // The remote-config lane starts directly on B: no request or probe ever reaches A again.
        let configResult: Result<RemoteConfigFetchResult, BackendError>? = waitUntilValue { completion in
            backend.remoteConfigAPI.getRemoteConfig(
                request: .init(fetchContext: .appStart, appUserID: Self.appUserID),
                isAppBackgrounded: false,
                completion: completion
            )
        }

        expect(configResult).to(beSuccess())
        expect(sourceA.value) == [Self.customerInfoPath, Self.healthPath]
        expect(sourceB.value.count) == 2
        expect(sourceB.value.last).to(beginWith("/v1/config"))
    }

    // MARK: - Helpers

    /// Wires the production stack: the `Backend` convenience init builds the real `HTTPClient`s, the
    /// shared `APISourceFailover` and the real `SourceHealthChecker`; sources come from an in-memory
    /// `sources` topic pointing at `sources` in order.
    private static func createBackend(sources: [String], usesRemoteConfigAPISources: Bool = true) -> Backend {
        let systemInfo = MockSystemInfo(
            finishTransactions: true,
            dangerousSettings: DangerousSettings(
                autoSyncPurchases: true,
                internalSettings: DangerousSettings.Internal(
                    usesRemoteConfigAPISources: usesRemoteConfigAPISources
                )
            )
        )
        return Backend(
            systemInfo: systemInfo,
            eTagManager: MockETagManager(),
            operationDispatcher: OperationDispatcher(),
            attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                   systemInfo: systemInfo),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: RemoteConfigSourceProvider(
                topicStore: APISourceTopicStore(urls: sources.map { "https://\($0)/" })
            )
        )
    }

    private func fetchCustomerInfo(_ backend: Backend) -> Result<CustomerInfo, BackendError>? {
        return waitUntilValue { completion in
            backend.getCustomerInfo(appUserID: Self.appUserID,
                                    isAppBackgrounded: false,
                                    allowComputingOffline: false) {
                completion($0)
            }
        }
    }

    private func isServerError(_ result: Result<CustomerInfo, BackendError>?) -> Bool {
        guard case let .failure(.networkError(networkError)) = result else { return false }
        return networkError.isServerDown
    }

    /// Stubs `host`, routing its health endpoint and its API endpoint by path (like Android's
    /// path-routing MockWebServer dispatcher) and recording every request's path in order.
    private func stubSource(
        host: String,
        endpoint: @escaping () -> HTTPStubsResponse,
        health: @escaping () -> HTTPStubsResponse = {
            BackendAPISourceFailoverIntegrationTests.response(200)
        }
    ) -> Atomic<[String]> {
        let recordedPaths: Atomic<[String]> = .init([])
        stub(condition: isHost(host)) { request in
            let path = request.url?.path ?? ""
            recordedPaths.modify { $0.append(path) }
            return path == Self.healthPath ? health() : endpoint()
        }
        return recordedPaths
    }

    private static func response(_ statusCode: Int32) -> HTTPStubsResponse {
        return HTTPStubsResponse(jsonObject: BaseBackendTests.serverErrorResponse,
                                 statusCode: statusCode,
                                 headers: nil)
    }

    private static func customerInfoResponse() -> HTTPStubsResponse {
        return HTTPStubsResponse(jsonObject: BaseBackendTests.validCustomerResponse,
                                 statusCode: 200,
                                 headers: nil)
    }

    /// A connection-level failure with the same `NSURLErrorDomain` classification as a real host
    /// whose port refuses connections.
    private static func connectionRefused() -> HTTPStubsResponse {
        return HTTPStubsResponse(error: URLError(.cannotConnectToHost))
    }

}

/// A minimal `sources` topic store exposing API sources in order (priority = index), matching the
/// backend topic shape.
private final class APISourceTopicStore: RemoteConfigTopicStoreType {

    private let urls: [String]

    init(urls: [String]) {
        self.urls = urls
    }

    func topic(_ topic: RemoteConfigTopic) -> RemoteConfiguration.ConfigTopic? {
        guard topic == .sources else { return nil }
        return ["api": RemoteConfiguration.ConfigItem(content: [
            "sources": .array(self.urls.enumerated().map { priority, url in
                .object([
                    "url": .string(url),
                    "priority": .int(priority),
                    "weight": .int(1)
                ])
            })
        ])]
    }

}
