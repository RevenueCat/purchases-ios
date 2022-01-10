//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionFetcherTests.swift
//  PurchasesTests
//
//  Created by César de la Vega on 7/17/20.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class AttributionPosterTests: XCTestCase {

    var attributionFetcher: AttributionFetcher!
    var attributionPoster: AttributionPoster!
    var deviceCache: MockDeviceCache!
    var identityManager: MockIdentityManager!
    var backend: MockBackend!
    var subscriberAttributesManager: MockSubscriberAttributesManager!
    var attributionFactory: AttributionTypeFactory! = MockAttributionTypeFactory()
    // swiftlint:disable:next force_try
    var systemInfo: MockSystemInfo! = try! MockSystemInfo(platformFlavor: "iOS",
                                                          platformFlavorVersion: "3.2.1",
                                                          finishTransactions: true)

    let userDefaultsSuiteName = "testUserDefaults"

    override func setUp() {
        super.setUp()

        let userID = "userID"
        deviceCache = MockDeviceCache(systemInfo: MockSystemInfo(finishTransactions: false),
                                      userDefaults: UserDefaults(suiteName: userDefaultsSuiteName)!)
        deviceCache.cache(appUserID: userID)
        backend = MockBackend()
        attributionFetcher = AttributionFetcher(attributionFactory: attributionFactory, systemInfo: systemInfo)
        subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: AttributionDataMigrator())
        identityManager = MockIdentityManager(mockAppUserID: userID)
        attributionPoster = AttributionPoster(deviceCache: deviceCache,
                                              identityManager: identityManager,
                                              backend: backend,
                                              attributionFetcher: attributionFetcher,
                                              subscriberAttributesManager: subscriberAttributesManager)
        resetAttributionStaticProperties()
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
    }

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        }

        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true
        MockAdClientProxy.requestAttributionDetailsCallCount = 0
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        UserDefaults.standard.synchronize()
        resetAttributionStaticProperties()
    }

    func testPostAttributionDataSkipsIfAlreadySent() {
        let userID = "userID"
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

    }

    func testPostAppleSearchAdsAttributionDataSkipsIfAlreadySent() {
        let userID = "userID"
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .appleSearchAds,
                               networkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .appleSearchAds,
                               networkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0

    }

    func testPostAttributionDataDoesntSkipIfNetworkChanged() {
        let userID = "userID"
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .facebook,
                               networkUserId: userID)

        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

    func testPostAttributionDataDoesntSkipIfDifferentUserIdButSameNetwork() {
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .adjust,
                               networkUserId: "attributionUser1")
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .adjust,
                               networkUserId: "attributionUser2")

        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

    func testPostAppleSearchAdsAttributionDataDoesntSkipIfDifferentUserIdButSameNetwork() {
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.post(attributionData: ["something": "here"],
                               fromNetwork: .appleSearchAds,
                               networkUserId: "attributionUser1")
        expect(self.backend.invokedPostAttributionDataCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0

        attributionPoster.post(attributionData: ["something": "else"],
                               fromNetwork: .appleSearchAds,
                               networkUserId: "attributionUser2")

        expect(self.backend.invokedPostAttributionDataCount) == 2
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfATTFrameworkNotIncludedOnNewOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = false

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfIAdFrameworkNotIncluded() {
        MockAttributionTypeFactory.shouldReturnAdClientProxy = false
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 0
    }

    // `MockTrackingManagerProxy.mockAuthorizationStatus isn't available on tvOS
    #if os(iOS)

    func testPostAppleSearchAdsAttributionIfNeededPostsIfATTFrameworkNotIncludedOnOldOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = false

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 1
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorizedOnNewOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = true

        MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 1
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorizedOnOldOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
        MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 1
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthNotDeterminedOnOldOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
        MockTrackingManagerProxy.mockAuthorizationStatus = .notDetermined
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 1
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAuthNotDeterminedOnNewOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = true

        MockTrackingManagerProxy.mockAuthorizationStatus = .notDetermined
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorizedOnOldOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
        MockTrackingManagerProxy.mockAuthorizationStatus = .denied
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorizedOnNewOS() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
        MockTrackingManagerProxy.mockAuthorizationStatus = .denied
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAlreadySent() throws {
        guard #available(iOS 14, *) else { throw XCTSkip() }

        MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 1

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClientProxy.requestAttributionDetailsCallCount) == 1
    }

    #endif
}
