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

    func testCanRotateAdClient() {
        let expected = "ADClient"
        let randomized = AttributionTypeFactory.rot13(expected)

        expect { randomized }.notTo(equal(expected))
        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateASIdentifierManager() {
        let expected = "ASIdentifierManager"
        let randomized = AttributionTypeFactory.rot13(expected)

        expect { randomized }.notTo(equal(expected))
        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateASIdentifierManagerBack() {
        let expected = "ASIdentifierManager"
        let randomized = self.attributionTypeFactory.mangledIdentifierClassName

        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateAdvertisingIdentifier() {
        let expected = "advertisingIdentifier"

        let randomized = AttributionTypeFactory.rot13(expected)
        expect { randomized }.notTo(equal(expected))
        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateAdvertisingIdentifierBack() {
        let expected = "advertisingIdentifier"
        let randomized = self.attributionTypeFactory.mangledIdentifierPropertyName

        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateTrackingManager() {
        let expected = "ATTrackingManager"
        let randomized = AttributionTypeFactory.rot13(expected)

        expect { randomized }.notTo(equal(expected))
        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateTrackingManagerBack() {
        let expected = "ATTrackingManager"
        let randomized = self.attributionTypeFactory.mangledTrackingClassName

        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateTrackingAuthorizationStatus() {
        let expected = "trackingAuthorizationStatus"

        let randomized = AttributionTypeFactory.rot13(expected)
        expect { randomized }.notTo(equal(expected))
        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }

    func testCanRotateTrackingAuthorizationStatusBack() {
        let expected = "trackingAuthorizationStatus"
        let randomized = self.attributionTypeFactory.mangledAuthStatusPropertyName

        expect { AttributionTypeFactory.rot13(randomized) }.to(equal(expected))
    }
}
