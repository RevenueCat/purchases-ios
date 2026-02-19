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
    var systemInfo: MockSystemInfo! =  MockSystemInfo(
        platformInfo: .init(flavor: "iOS", version: "3.2.1"),
        finishTransactions: true
    )

    var userDefaultsSuiteName: String!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        let userID = "userID"
        let systemInfo = MockSystemInfo(finishTransactions: false)
        systemInfo.stubbedIsSandbox = BundleSandboxEnvironmentDetector.default.isSandbox
        self.userDefaultsSuiteName = "AttributionPosterTests.\(self.name).\(UUID().uuidString)"
        self.userDefaults = UserDefaults(suiteName: self.userDefaultsSuiteName)
        self.userDefaults.removePersistentDomain(forName: self.userDefaultsSuiteName)
        self.deviceCache = MockDeviceCache(systemInfo: systemInfo,
                                           userDefaults: self.userDefaults)
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
                                                   subscriberAttributesManager: self.subscriberAttributesManager,
                                                   systemInfo: self.systemInfo)
        self.resetAttributionStaticProperties()
        self.backend.stubbedPostAttributionDataCompletionResult = (nil, ())
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())
    }

    private func resetAttributionStaticProperties() {
        #if !os(watchOS)
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        }
        #endif

        MockAttributionTypeFactory.shouldReturnAdClientProxy = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true
    }

    override func tearDown() {
        if let suiteName = self.userDefaultsSuiteName {
            self.userDefaults?.removePersistentDomain(forName: suiteName)
            self.userDefaults?.removeSuite(named: suiteName)
        }
        resetAttributionStaticProperties()
        super.tearDown()
    }

}

class AttributionPosterTests: BaseAttributionPosterTests {

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

    @available(*, deprecated)
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

    @available(*, deprecated)
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

}

#if canImport(AdServices)
@available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
class AdServicesAttributionPosterTests: BaseAttributionPosterTests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS14APIAvailableOrSkipTest()
    }

    func testAdServicesTokenToPostIfNeededReturnsNilIfAlreadySent() async throws {
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        var token = await self.attributionPoster.adServicesTokenToPostIfNeeded
        expect(token).toNot(beNil())

        let error = await Async.call { completion in
            self.attributionPoster.postAdServicesTokenOncePerInstallIfNeeded(completion: completion)
        }
        expect(error).to(beNil())

        token = await self.attributionPoster.adServicesTokenToPostIfNeeded
        expect(token).to(beNil())
    }

    func testPostAdServicesTokenOncePerInstallIfNeededSkipsIfAlreadySent() throws {
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        try self.postAdServicesTokenOncePerInstallIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1

        try self.postAdServicesTokenOncePerInstallIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAdServicesTokenOncePerInstallIfNeededSkipsIfNilToken() throws {
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        self.attributionFetcher.adServicesTokenToReturn = nil

        try self.postAdServicesTokenOncePerInstallIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAdServicesTokenOncePerInstallIfNeededDoesNotCacheOnAPIError() throws {
        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey,
                                 originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                                 message: nil),
                           400)
        )

        backend.stubbedPostAdServicesTokenCompletionResult = .failure(stubbedError)

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenOncePerInstallIfNeeded()
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 0
    }

    func testPostAdServicesTokenCachesProperData() throws {
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        let adServicesToken = "asdf"
        self.attributionFetcher.adServicesTokenToReturn = adServicesToken

        try self.postAdServicesTokenOncePerInstallIfNeeded()

        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentParameters) ==
            ([.adServices: adServicesToken], currentUserProvider.currentAppUserID)
    }

    private func postAdServicesTokenOncePerInstallIfNeeded() throws {
        let result: Error?? = waitUntilValue { completion in
            self.attributionPoster.postAdServicesTokenOncePerInstallIfNeeded(completion: completion)
        }
        let error = try XCTUnwrap(result)
        expect(error).to(beNil())
    }

}
#endif

class AttributionPosterUIPreviewModeTests: BaseAttributionPosterTests {

    override func setUp() {
        self.systemInfo = MockSystemInfo(finishTransactions: true, uiPreviewMode: true)
        super.setUp()
    }

    func testPostPostponedAttributionDataDoesNothingInUIPreviewMode() {
        AttributionPoster.store(postponedAttributionData: ["test": "data"],
                                fromNetwork: .adjust,
                                forNetworkUserId: "testUser")

        attributionPoster.postPostponedAttributionDataIfNeeded()

        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAttributionDataDoesNothingInUIPreviewMode() {
        attributionPoster.post(attributionData: ["test": "data"],
                               fromNetwork: .adjust,
                               networkUserId: "testUser")

        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }
}
