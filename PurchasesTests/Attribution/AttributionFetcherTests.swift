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
    var attributionFactory: AttributionTypeFactory! = AttributionTypeFactory()

    let userDefaultsSuiteName = "testUserDefaults"
    
    override func setUp() {
        super.setUp()
        deviceCache = MockDeviceCache(UserDefaults(suiteName: userDefaultsSuiteName)!)
        let userID = "userID"
        deviceCache.cacheAppUserID(userID)

        identityManager = MockIdentityManager(mockAppUserID: userID)
        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: MockBackend(),
                                                  attributionFactory: attributionFactory)
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

    }

    func testPostAppleSearchAdsAttributionIfNeededPostsIfAuthorized() {

    }

    func testPostAppleSearchAdsAttributionIfNeededSkipsIfAlreadySent() {

    }
}
