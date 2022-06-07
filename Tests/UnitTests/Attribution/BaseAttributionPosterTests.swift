//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BaseAttributionPosterTests.swift
//
//  Created by Madeline Beyl on 6/7/22.

import Foundation

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class BaseAttributionPosterTests: TestCase {

    var attributionFetcher: MockAttributionFetcher!
    var attributionPoster: AttributionPoster!
    var deviceCache: MockDeviceCache!
    var currentUserProvider: MockCurrentUserProvider!
    var backend: MockBackend!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var attributionFactory: AttributionTypeFactory! = MockAttributionTypeFactory()
    // swiftlint:disable:next force_try
    var systemInfo: MockSystemInfo! = try! MockSystemInfo(
        platformInfo: .init(flavor: "iOS", version: "3.2.1"),
        finishTransactions: true)

    let userDefaultsSuiteName = "testUserDefaults"

    override func setUp() {
        super.setUp()

        let userID = "userID"
        deviceCache = MockDeviceCache(systemInfo: MockSystemInfo(finishTransactions: false),
                                      userDefaults: UserDefaults(suiteName: userDefaultsSuiteName)!)
        deviceCache.cache(appUserID: userID)
        backend = MockBackend()
        attributionFetcher = MockAttributionFetcher(attributionFactory: attributionFactory, systemInfo: systemInfo)
        subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: AttributionDataMigrator())
        currentUserProvider = MockCurrentUserProvider(mockAppUserID: userID)
        attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                              currentUserProvider: currentUserProvider,
                                              backend: backend,
                                              attributionFetcher: attributionFetcher,
                                              subscriberAttributesManager: subscriberAttributesManager)
        resetAttributionStaticProperties()
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        UserDefaults.standard.synchronize()
        resetAttributionStaticProperties()
    }

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        }

        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true
    }

}
