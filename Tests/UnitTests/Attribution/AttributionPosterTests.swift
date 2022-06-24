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
//
//  Created by Madeline Beyl on 6/7/22.

import Foundation
import Nimble
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
        self.deviceCache = MockDeviceCache(sandboxEnvironmentDetector: BundleSandboxEnvironmentDetector.default,
                                           userDefaults: UserDefaults(suiteName: userDefaultsSuiteName)!)
        self.deviceCache.cache(appUserID: userID)
        self.backend = MockBackend()
        self.attributionFetcher = MockAttributionFetcher(attributionFactory: attributionFactory, systemInfo: systemInfo)
        self.subscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.backend,
            deviceCache: self.deviceCache,
            operationDispatcher: MockOperationDispatcher(),
            attributionFetcher: self.attributionFetcher,
            attributionDataMigrator: AttributionDataMigrator())
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: userID)
        self.attributionPoster = AttributionPoster(deviceCache: self.deviceCache,
                                                   currentUserProvider: self.currentUserProvider,
                                                   backend: self.backend,
                                                   attributionFetcher: self.attributionFetcher,
                                                   subscriberAttributesManager: self.subscriberAttributesManager)
        self.resetAttributionStaticProperties()
        self.backend.stubbedPostAttributionDataCompletionResult = (nil, ())
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        UserDefaults.standard.synchronize()
        resetAttributionStaticProperties()
        super.tearDown()
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

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        }
        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true
        MockAdClientProxy.requestAttributionDetailsCallCount = 0
    }

}

#if canImport(AdServices)
@available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
class AdServicesAttributionPosterTests: BaseAttributionPosterTests {

    func testPostAdServicesTokenIfNeededSkipsIfAlreadySent() {
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1

        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAdServicesTokenIfNeededSkipsIfNilToken() throws {
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAdServicesTokenIfNeededDoesNotCacheOnAPIError() throws {
        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey, message: nil),
                           400)
        )

        backend.stubbedPostAdServicesTokenCompletionResult = .failure(stubbedError)

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 0
    }

}
#endif

class AttributionPosterTests: BaseAttributionPosterTests {

    // TODO move stuff back into here?

}
