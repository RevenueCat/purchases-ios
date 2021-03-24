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
        let randomized = self.attributionTypeFactory.mangledIdentifierClassName

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
        let randomized = self.attributionTypeFactory.mangledIdentifierPropertyName

        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateATTrackingManager() {
        let expected = "ATTrackingManager"
        let randomized = attributionTypeFactory.rot13(expected)

        expect { randomized }.notTo(equal(expected))
        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateATTrackingManagerBack() {
        let expected = "ATTrackingManager"
        let randomized = self.attributionTypeFactory.mangledTrackingClassName

        expect { self.attributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }
}