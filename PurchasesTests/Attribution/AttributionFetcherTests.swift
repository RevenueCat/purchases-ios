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

        if #available(iOS 14, macOS 11, tvOS 14, *) {
            MockATTrackingManager.mockAuthorizationStatus = .denied
        }
        MockAttributionTypeFactory.shouldReturnAdClientClass = true
        MockAttributionTypeFactory.shouldReturnTrackingManagerClass = true
        MockAdClient.requestAttributionDetailsCallCount = 0
        backend.stubbedPostAttributionDataCompletionResult = (nil, ())
    }
    
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        UserDefaults.standard.synchronize()
    }

    func testCanRotateASIdentifierManager() {
        let expected = "ASIdentifierManager"
        let randomized = attributionFetcher.rot13(expected)
        
        expect { randomized } .notTo(equal(expected))
        expect { self.attributionFetcher.rot13(randomized) } .to(equal(expected))
    }
    
    func testCanRotateASIdentifierManagerBack() {
        let expected = "ASIdentifierManager"
        let randomized = "NFVqragvsvreZnantre"
        
        expect { self.attributionFetcher.rot13(randomized) } .to(equal(expected))
    }
    
    func testCanRotateAdvertisingIdentifier() {
        let expected = "advertisingIdentifier"
        
        let randomized = attributionFetcher.rot13(expected)
        expect { randomized } .notTo(equal(expected))
        expect { self.attributionFetcher.rot13(randomized) } .to(equal(expected))
    }
    
    func testCanRotateAdvertisingIdentifierBack() {
        let expected = "advertisingIdentifier"
        let randomized = "nqiregvfvatVqragvsvre"
        
        expect { self.attributionFetcher.rot13(randomized) } .to(equal(expected))
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
