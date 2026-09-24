//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendLanesTests.swift
//
//  Created by Antonio Pallares on 18/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendLanesTests: TestCase {

    func testDedicatedLaneGetsItsOwnConfigurationClientAndQueue() {
        let lanes = self.makeLanes(dedicatedLanes: [.remoteConfig, .checkout])

        let defaultConfig = lanes.defaultConfiguration
        let remoteConfigConfig = lanes[GetRemoteConfigOperation.self]
        let checkoutConfig = lanes[PostHostedCheckoutOperation.self]

        expect(defaultConfig).toNot(beIdenticalTo(remoteConfigConfig))
        expect(defaultConfig).toNot(beIdenticalTo(checkoutConfig))
        expect(remoteConfigConfig).toNot(beIdenticalTo(checkoutConfig))

        expect(defaultConfig.httpClient).toNot(beIdenticalTo(remoteConfigConfig.httpClient))
        expect(defaultConfig.httpClient).toNot(beIdenticalTo(checkoutConfig.httpClient))
        expect(remoteConfigConfig.httpClient).toNot(beIdenticalTo(checkoutConfig.httpClient))

        expect(defaultConfig.operationQueue).toNot(beIdenticalTo(remoteConfigConfig.operationQueue))
        expect(defaultConfig.operationQueue).toNot(beIdenticalTo(checkoutConfig.operationQueue))
        expect(remoteConfigConfig.operationQueue).toNot(beIdenticalTo(checkoutConfig.operationQueue))
    }

    func testUnlistedLaneFallsBackToDefaultConfiguration() {
        let lanes = self.makeLanes(dedicatedLanes: [.checkout])

        expect(lanes.defaultConfiguration).to(beIdenticalTo(lanes[GetRemoteConfigOperation.self]))
    }

    func testDefaultInDedicatedLanesDoesNotCreateSecondConfiguration() {
        let lanes = self.makeLanes(dedicatedLanes: [.default, .checkout])

        expect(lanes.defaultConfiguration).to(beIdenticalTo(lanes[GetRemoteConfigOperation.self]))
        expect(lanes.defaultConfiguration).toNot(beIdenticalTo(lanes[PostHostedCheckoutOperation.self]))
    }

    func testDiagnosticsQueueIsSharedAcrossLanes() {
        let lanes = self.makeLanes(dedicatedLanes: [.remoteConfig, .checkout])

        expect(lanes.defaultConfiguration.diagnosticsQueue)
            .to(beIdenticalTo(lanes[GetRemoteConfigOperation.self].diagnosticsQueue))
        expect(lanes.defaultConfiguration.diagnosticsQueue)
            .to(beIdenticalTo(lanes[PostHostedCheckoutOperation.self].diagnosticsQueue))
    }

    func testQueueNamingAndQualityOfService() {
        let lanes = self.makeLanes(dedicatedLanes: [.remoteConfig, .checkout])

        expect(lanes.defaultConfiguration.operationQueue.name) == "RC Backend Queue"
        expect(lanes[GetRemoteConfigOperation.self].operationQueue.name) == "RC Remote Config Queue"
        expect(lanes[PostHostedCheckoutOperation.self].operationQueue.name) == "RC Checkout Queue"

        expect(lanes.defaultConfiguration.operationQueue.maxConcurrentOperationCount) == 1
        expect(lanes[GetRemoteConfigOperation.self].operationQueue.maxConcurrentOperationCount) == 1
        expect(lanes[PostHostedCheckoutOperation.self].operationQueue.maxConcurrentOperationCount) == 1

        expect(lanes.defaultConfiguration.operationQueue.qualityOfService) == .default
        expect(lanes[GetRemoteConfigOperation.self].operationQueue.qualityOfService) == .default
        expect(lanes[PostHostedCheckoutOperation.self].operationQueue.qualityOfService) == .userInitiated
    }

    func testMissingDedicatedLaneLogsWarning() {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let operationDispatcher = OperationDispatcher()
        let defaultConfiguration = self.makeConfig(client: self.makeMockClient(systemInfo: systemInfo),
                                                   lane: .default,
                                                   systemInfo: systemInfo,
                                                   operationDispatcher: operationDispatcher)
        let checkoutConfiguration = self.makeConfig(client: self.makeMockClient(systemInfo: systemInfo),
                                                    lane: .checkout,
                                                    systemInfo: systemInfo,
                                                    operationDispatcher: operationDispatcher)
        let partialLanes = BackendLanes(
            defaultConfiguration: defaultConfiguration,
            dedicatedConfigurations: [.checkout: checkoutConfiguration]
        )

        self.logger.clearMessages()
        _ = partialLanes[GetRemoteConfigOperation.self]
        self.logger.verifyMessageWasLogged(
            Strings.network.missing_dedicated_lane_configuration(laneName: RequestLane.remoteConfig.name),
            level: .warn
        )

        self.logger.clearMessages()
        _ = partialLanes.defaultConfiguration
        self.logger.verifyMessageWasNotLogged(
            Strings.network.missing_dedicated_lane_configuration(laneName: RequestLane.default.name),
            level: .warn,
            allowNoMessages: true
        )

        self.logger.clearMessages()
        let singleLane = BackendLanes(configuration: defaultConfiguration)
        _ = singleLane[GetRemoteConfigOperation.self]
        _ = singleLane[PostHostedCheckoutOperation.self]
        self.logger.verifyMessageWasNotLogged(
            Strings.network.missing_dedicated_lane_configuration(laneName: RequestLane.remoteConfig.name),
            level: .warn,
            allowNoMessages: true
        )
    }

    func testOperationsDeclareExpectedLanes() {
        expect(PostExternalPurchaseTokenOperation.lane) == .checkout
        expect(PostHostedCheckoutOperation.lane) == .checkout
        expect(GetRemoteConfigOperation.lane) == .remoteConfig
        expect(GetRemoteConfigFallbackOperation.lane) == .remoteConfig
        expect(GetOfferingsOperation.lane) == .default
    }

    func testOperationBasedSubscriptRoutesToDedicatedLaneConfiguration() {
        let lanes = self.makeLanes(dedicatedLanes: [.remoteConfig, .checkout])

        expect(lanes[PostExternalPurchaseTokenOperation.self])
            .to(beIdenticalTo(lanes[PostHostedCheckoutOperation.self]))
        expect(lanes[GetRemoteConfigOperation.self])
            .to(beIdenticalTo(lanes[GetRemoteConfigFallbackOperation.self]))
        expect(lanes[GetOfferingsOperation.self])
            .to(beIdenticalTo(lanes.defaultConfiguration))
    }

    func testClearHTTPClientCachesClearsSharedETagCacheOnce() {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let eTagManager = MockETagManager()
        let backend = Backend(
            systemInfo: systemInfo,
            httpClientTimeout: .default,
            eTagManager: eTagManager,
            tokenManager: MockTokenManager(),
            operationDispatcher: OperationDispatcher(),
            attributionFetcher: AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                   systemInfo: systemInfo),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default)
        )

        backend.clearHTTPClientCaches()

        expect(eTagManager.invokedClearCachesCount) == 1
    }

}

private extension BackendLanesTests {

    func makeLanes(dedicatedLanes: Set<RequestLane>) -> BackendLanes {
        let systemInfo = MockSystemInfo(finishTransactions: true)
        let factory = BackendLanesFactory(
            systemInfo: systemInfo,
            eTagManager: MockETagManager(),
            tokenManager: MockTokenManager(),
            diagnosticsTracker: nil,
            networkTimeout: .default,
            apiSourceFailover: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default),
            operationDispatcher: OperationDispatcher(),
            offlineCustomerInfoCreator: nil,
            dateProvider: DateProvider()
        )
        return factory.makeLanes(dedicatedLanes: dedicatedLanes)
    }

    func makeMockClient(systemInfo: SystemInfo) -> MockHTTPClient {
        return MockHTTPClient(systemInfo: systemInfo,
                              eTagManager: MockETagManager(),
                              tokenManager: MockTokenManager(),
                              diagnosticsTracker: nil)
    }

    func makeConfig(client: MockHTTPClient,
                    lane: RequestLane,
                    systemInfo: SystemInfo,
                    operationDispatcher: OperationDispatcher) -> BackendConfiguration {
        return BackendConfiguration(
            httpClient: client,
            operationDispatcher: operationDispatcher,
            operationQueue: Backend.QueueProvider.createQueue(for: lane),
            diagnosticsQueue: Backend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: systemInfo,
            offlineCustomerInfoCreator: nil,
            dateProvider: DateProvider()
        )
    }

}
