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
        self.deviceCache = MockDeviceCache(sandboxEnvironmentDetector: DefaultSandboxEnvironmentDetector(),
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
        self.backend.stubbedPostAdServicesTokenCompletionResult = .success(())
    }

    override func tearDown() {
            UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
            UserDefaults.standard.synchronize()
            resetAttributionStaticProperties()
            super.tearDown()
        }

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManagerProxy.mockAuthorizationStatus = .authorized
        }

        MockAttributionTypeFactory.shouldReturnTrackingManagerProxy = true
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
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())
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
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())

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

}
