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
    var deviceCache: MockDeviceCache!
    var identityManager: MockIdentityManager!
    var backend: MockBackend!
    var attributionFactory: AttributionTypeFactory! = MockAttributionTypeFactory()
    var systemInfo: MockSystemInfo! = try! MockSystemInfo(platformFlavor: "iOS",
                                                          platformFlavorVersion: "3.2.1",
                                                          finishTransactions: true)

    let userDefaultsSuiteName = "testUserDefaults"
    
    override func setUp() {
        super.setUp()
        let userID = "userID"
        deviceCache = MockDeviceCache(userDefaults: UserDefaults(suiteName: userDefaultsSuiteName)!)
        deviceCache.cache(appUserID: userID)
        backend = MockBackend()
        identityManager = MockIdentityManager(mockAppUserID: userID)
        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFactory: attributionFactory,
                                                  systemInfo: systemInfo)
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
        
        attributionFetcher.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 1

        attributionFetcher.postAttributionData(["something": "else"],
                                               from: .adjust,
                                               forNetworkUserId: userID)

        expect(self.backend.invokedPostAttributionDataCount) == 1

    }

    func testPostAttributionDataDoesntSkipIfNetworkUserIdChanged() {
        let userID = "userID"
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionFetcher.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(self.backend.invokedPostAttributionDataCount) == 1

        attributionFetcher.postAttributionData(["something": "else"],
                                               from: .facebook,
                                               forNetworkUserId: userID)

        expect(self.backend.invokedPostAttributionDataCount) == 2
    }

    func testPostAttributionDataDoesntSkipIfSameUserIdButDifferentNetwork() {
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionFetcher.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: "attributionUser1")
        expect(self.backend.invokedPostAttributionDataCount) == 1

        attributionFetcher.postAttributionData(["something": "else"],
                                               from: .facebook,
                                               forNetworkUserId: "attributionUser2")

        expect(self.backend.invokedPostAttributionDataCount) == 2
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfATTFrameworkNotIncludedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = false

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfATTFrameworkNotIncludedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = false

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfIAdFrameworkNotIncluded() {
        MockAttributionTypeFactory.shouldReturnAdClientClass = false
        MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

        self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClient.requestAttributionDetailsCallCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorizedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
            MockTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorizedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthNotDeterminedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockTrackingManager.mockAuthorizationStatus = .notDetermined
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAuthNotDeterminedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true

            MockTrackingManager.mockAuthorizationStatus = .notDetermined
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }


    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorizedOnOldOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = false
            MockTrackingManager.mockAuthorizationStatus = .denied
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorizedOnNewOS() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            systemInfo.stubbedIsOperatingSystemAtLeastVersion = true
            MockTrackingManager.mockAuthorizationStatus = .denied
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAlreadySent() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }
}
