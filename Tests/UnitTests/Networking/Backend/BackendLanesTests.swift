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

        let defaultConfig = lanes[.default]
        let remoteConfigConfig = lanes[.remoteConfig]
        let checkoutConfig = lanes[.checkout]

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

        expect(lanes[.default]).to(beIdenticalTo(lanes[.remoteConfig]))
    }

    func testDefaultInDedicatedLanesDoesNotCreateSecondConfiguration() {
        let lanes = self.makeLanes(dedicatedLanes: [.default, .checkout])

        expect(lanes[.default]).to(beIdenticalTo(lanes[.remoteConfig]))
        expect(lanes[.default]).toNot(beIdenticalTo(lanes[.checkout]))
    }

    func testDiagnosticsQueueIsSharedAcrossLanes() {
        let lanes = self.makeLanes(dedicatedLanes: [.remoteConfig, .checkout])

        expect(lanes[.default].diagnosticsQueue).to(beIdenticalTo(lanes[.remoteConfig].diagnosticsQueue))
        expect(lanes[.default].diagnosticsQueue).to(beIdenticalTo(lanes[.checkout].diagnosticsQueue))
    }

    func testQueueNamingAndQualityOfService() {
        let lanes = self.makeLanes(dedicatedLanes: [.remoteConfig, .checkout])

        expect(lanes[.default].operationQueue.name) == "RC Backend Queue"
        expect(lanes[.remoteConfig].operationQueue.name) == "RC Remote Config Queue"
        expect(lanes[.checkout].operationQueue.name) == "RC Checkout Queue"

        expect(lanes[.default].operationQueue.maxConcurrentOperationCount) == 1
        expect(lanes[.remoteConfig].operationQueue.maxConcurrentOperationCount) == 1
        expect(lanes[.checkout].operationQueue.maxConcurrentOperationCount) == 1

        expect(lanes[.default].operationQueue.qualityOfService) == .default
        expect(lanes[.remoteConfig].operationQueue.qualityOfService) == .default
        expect(lanes[.checkout].operationQueue.qualityOfService) == .userInitiated
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

}
