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

    override func setUp() {
        super.setUp()
        deviceCache = MockDeviceCache()
        identityManager = MockIdentityManager(mockAppUserID: "userID")
        attributionFetcher = RCAttributionFetcher(deviceCache: deviceCache,
                                                  identityManager: identityManager,
                                                  backend: MockBackend())
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

}
