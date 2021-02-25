//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble
import Purchases

class AttributionTypeFactoryTests: XCTestCase {

    var attributionTypeFactory: AttributionTypeFactory!

    override func setUp() {
        super.setUp()
        attributionTypeFactory = AttributionTypeFactory()
    }

    func testCanRotateASIdentifierManager() {
        let expected = "ASIdentifierManager"
        let randomized = attributionTypeFactory.rot13(expected)

        expect { randomized }.notTo(equal(expected))
        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateASIdentifierManagerBack() {
        let expected = "ASIdentifierManager"
        let randomized = "NFVqragvsvreZnantre"

        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateAdvertisingIdentifier() {
        let expected = "advertisingIdentifier"

        let randomized = attributionTypeFactory.rot13(expected)
        expect { randomized }.notTo(equal(expected))
        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateAdvertisingIdentifierBack() {
        let expected = "advertisingIdentifier"
        let randomized = "nqiregvfvatVqragvsvre"

        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }
}