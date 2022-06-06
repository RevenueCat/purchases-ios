//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionPosterTests.swift
//  PurchasesTests
//
//  Created by César de la Vega on 7/17/20.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class AttributionPosterTests: TestCase {

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
        backend.stubbedPostAdServicesTokenCompletionResult = Result.success(())
    }

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        }

        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        UserDefaults.standard.synchronize()
        resetAttributionStaticProperties()
    }

    func testPostAttributionDataSkipsIfAlreadySent() {
        let userID = "userID"

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: userID)

        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1
    }

    func testPostAttributionDataDoesntSkipIfNetworkChanged() {
        let userID = "userID"
        backend.stubbedPostAdServicesTokenCompletionResult = Result.success(())
        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .facebook,
                               networkUserId: userID)
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

    func testPostAttributionDataDoesntSkipIfDifferentUserIdButSameNetwork() {
        backend.stubbedPostAdServicesTokenCompletionResult = Result.success(())

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: "attributionUser1")
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .adjust,
                               networkUserId: "attributionUser2")
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

#if canImport(AdServices)
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testPostAdServicesTokenIfNeededSkipsIfAlreadySent() throws {
        guard #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        backend.stubbedPostAdServicesTokenCompletionResult = Result.success(())

        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1

        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testPostAdServicesTokenIfNeededSkipsIfNilToken() throws {
        guard #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }

        backend.stubbedPostAdServicesTokenCompletionResult = Result.success(())

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testPostAdServicesTokenIfNeededDoesNotCacheOnAPIError() throws {
        guard #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) else {
            throw XCTSkip("Required API is not available for this test.")
        }
        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey, message: nil),
                           400)
        )

        backend.stubbedPostAdServicesTokenCompletionResult = Result.failure(stubbedError)

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 0
    }

#endif

}
