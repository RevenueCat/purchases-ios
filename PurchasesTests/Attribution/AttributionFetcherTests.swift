//
//  AttributionFetcherTests.swift
//  PurchasesTests
//
//  Created by César de la Vega  on 7/17/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble
import Purchases

class AttributionFetcherTests: XCTestCase {

    var attributionFetcher: RCAttributionFetcher!
    var attributionPoster: RCAttributionPoster!
    var deviceCache: MockDeviceCache!
    var identityManager: MockIdentityManager!
    var backend: MockBackend!
    let subscriberAttributesManager = MockSubscriberAttributesManager()
    var attributionFactory: AttributionTypeFactory! = MockAttributionTypeFactory()
    var systemInfo: MockSystemInfo! = MockSystemInfo(platformFlavor: "iOS",
                                                     platformFlavorVersion: "3.2.1",
                                                     finishTransactions: true)

    let userDefaultsSuiteName = "testUserDefaults"
    
    override func setUp() {
        super.setUp()
        let userID = "userID"
        deviceCache = MockDeviceCache(UserDefaults(suiteName: userDefaultsSuiteName)!)
        deviceCache.cacheAppUserID(userID)
        backend = MockBackend()
        identityManager = MockIdentityManager(mockAppUserID: userID)
        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFactory: attributionFactory,
                                                  systemInfo: systemInfo)
        attributionPoster = RCAttributionPoster(deviceCache: deviceCache,
                                                identityManager: identityManager,
                                                backend: backend,
                                                systemInfo: systemInfo,
                                                attributionFetcher: attributionFetcher,
                                                subscriberAttributesManager: subscriberAttributesManager)
        resetAttributionStaticProperties()
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
    }

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManager.mockAuthorizationStatus = .authorized
        }
        MockAttributionTypeFactory.shouldReturnAdClientClass = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true
        MockAdClient.requestAttributionDetailsCallCount = 0
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
        
        attributionPoster.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.postAttributionData(["something": "else"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

    }
    
    func testPostAppleSearchAdsAttributionDataSkipsIfAlreadySent() {
        let userID = "userID"
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
        
        attributionPoster.postAttributionData(["something": "here"],
                                               from: .appleSearchAds,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0

        attributionPoster.postAttributionData(["something": "else"],
                                               from: .appleSearchAds,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0

    }
    
    func testPostAttributionDataDoesntSkipIfNetworkChanged() {
        let userID = "userID"
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.postAttributionData(["something": "else"],
                                               from: .facebook,
                                               forNetworkUserId: userID)

        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }

    func testPostAttributionDataDoesntSkipIfDifferentUserIdButSameNetwork() {
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: "attributionUser1")
        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 1

        attributionPoster.postAttributionData(["something": "else"],
                                               from: .adjust,
                                               forNetworkUserId: "attributionUser2")

        expect(self.backend.invokedPostAttributionDataCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 2
    }
    
    func testPostAppleSearchAdsAttributionDataDoesntSkipIfDifferentUserIdButSameNetwork() {
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionPoster.postAttributionData(["something": "here"],
                                               from: .appleSearchAds,
                                               forNetworkUserId: "attributionUser1")
        expect(self.backend.invokedPostAttributionDataCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0

        attributionPoster.postAttributionData(["something": "else"],
                                               from: .appleSearchAds,
                                               forNetworkUserId: "attributionUser2")

        expect(self.backend.invokedPostAttributionDataCount) == 2
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfATTFrameworkNotIncludedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = false

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
            expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfATTFrameworkNotIncludedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = false

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfIAdFrameworkNotIncluded() {
        MockAttributionTypeFactory.shouldReturnAdClientClass = false
        MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

        self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClient.requestAttributionDetailsCallCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorizedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
            MockTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorizedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthNotDeterminedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockTrackingManager.mockAuthorizationStatus = .notDetermined
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAuthNotDeterminedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true

            MockTrackingManager.mockAuthorizationStatus = .notDetermined
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }


    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorizedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockTrackingManager.mockAuthorizationStatus = .denied
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorizedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
            MockTrackingManager.mockAuthorizationStatus = .denied
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAlreadySent() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1

            self.attributionPoster.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

}
