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
                                                  attributionFactory: attributionFactory)
        resetAttributionStaticProperties()
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
    }

    private func resetAttributionStaticProperties() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockATTrackingManager.mockAuthorizationStatus = .authorized
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
        let backend = MockBackend()
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
        
        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFactory: attributionFactory)
        attributionFetcher.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(backend.invokedPostAttributionDataCount) == 1

        attributionFetcher.postAttributionData(["something": "else"],
                                               from: .adjust,
                                               forNetworkUserId: userID)

        expect(backend.invokedPostAttributionDataCount) == 1

    }

    func testPostAttributionDataDoesntSkipIfNetworkUserIdChanged() {
        let userID = "userID"
        let backend = MockBackend()
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFactory: attributionFactory)
        attributionFetcher.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: userID)
        expect(backend.invokedPostAttributionDataCount) == 1

        attributionFetcher.postAttributionData(["something": "else"],
                                               from: .facebook,
                                               forNetworkUserId: userID)

        expect(backend.invokedPostAttributionDataCount) == 2
    }

    func testPostAttributionDataDoesntSkipIfSameUserIdButDifferentNetwork() {
        let backend = MockBackend()
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())

        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: backend,
                                                  attributionFactory: attributionFactory)
        attributionFetcher.postAttributionData(["something": "here"],
                                               from: .adjust,
                                               forNetworkUserId: "attributionUser1")
        expect(backend.invokedPostAttributionDataCount) == 1

        attributionFetcher.postAttributionData(["something": "else"],
                                               from: .facebook,
                                               forNetworkUserId: "attributionUser2")

        expect(backend.invokedPostAttributionDataCount) == 2
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfNotAuthorized() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockATTrackingManager.mockAuthorizationStatus = .denied
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfATTFrameworkNotIncluded() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = false

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 0
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfIAdFrameworkNotIncluded() {
        MockAttributionTypeFactory.shouldReturnAdClientClass = false
        MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

        self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

        expect(MockAdClient.requestAttributionDetailsCallCount) == 0
    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorized() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockATTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAlreadySent() {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockATTrackingManager.mockAuthorizationStatus = .authorized
            MockAttributionTypeFactory.shouldReturnAdClientClass = true
            MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1

            self.attributionFetcher.postAppleSearchAdsAttributionIfNeeded()

            expect(MockAdClient.requestAttributionDetailsCallCount) == 1
        }
    }
}
