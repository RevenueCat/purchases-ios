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

    func testCanRotateASIdentifierManager() {
        let attributionFetcher = RCAttributionFetcher()
        
        let expected = "ASIdentifierManager"
        let randomized = attributionFetcher.rot13(expected)
        
        expect { randomized } .notTo(equal(expected))
        expect { attributionFetcher.rot13(randomized) } .to(equal(expected))
    }
    
    func testCanRotateASIdentifierManagerBack() {
        let attributionFetcher = RCAttributionFetcher()
        let expected = "ASIdentifierManager"
        let randomized = "NFVqragvsvreZnantre"
        
        expect { attributionFetcher.rot13(randomized) } .to(equal(expected))
    }
    
    func testCanRotateAdvertisingIdentifier() {
        let attributionFetcher = RCAttributionFetcher()
        let expected = "advertisingIdentifier"
        
        let randomized = attributionFetcher.rot13(expected)
        expect { randomized } .notTo(equal(expected))
        expect { attributionFetcher.rot13(randomized) } .to(equal(expected))
    }
    
    func testCanRotateAdvertisingIdentifierBack() {
        let attributionFetcher = RCAttributionFetcher()
        let expected = "advertisingIdentifier"
        let randomized = "nqiregvfvatVqragvsvre"
        
        expect { attributionFetcher.rot13(randomized) } .to(equal(expected))
    }

}
