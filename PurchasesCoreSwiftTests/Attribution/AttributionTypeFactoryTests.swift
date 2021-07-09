//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import XCTest
import Nimble
@testable import PurchasesCoreSwift

class AttributionTypeFactoryTests: XCTestCase {

    var attributionTypeFactory: AttributionTypeFactory!

    override func setUp() {
        super.setUp()
        attributionTypeFactory = AttributionTypeFactory()
    }

    func testCanRotateASIdentifierManager() {
        let expected = "ASIdentifierManager"
        let randomized = expected.rot13()

        expect { randomized }.notTo(equal(expected))
        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateASIdentifierManagerBack() {
        let expected = "ASIdentifierManager"
        let randomized = self.attributionTypeFactory.mangledIdentifierClassName

        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateAdvertisingIdentifier() {
        let expected = "advertisingIdentifier"

        let randomized = expected.rot13()
        expect { randomized }.notTo(equal(expected))
        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateAdvertisingIdentifierBack() {
        let expected = "advertisingIdentifier"
        let randomized = self.attributionTypeFactory.mangledIdentifierPropertyName

        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateTrackingManager() {
        let expected = "ATTrackingManager"
        let randomized = expected.rot13()

        expect { randomized }.notTo(equal(expected))
        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateTrackingManagerBack() {
        let expected = "ATTrackingManager"
        let randomized = self.attributionTypeFactory.mangledTrackingClassName

        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateTrackingAuthorizationStatus() {
        let expected = "trackingAuthorizationStatus"

        let randomized = expected.rot13()
        expect { randomized }.notTo(equal(expected))
        expect { randomized.rot13() }.to(equal(expected))
    }

    func testCanRotateTrackingAuthorizationStatusBack() {
        let expected = "trackingAuthorizationStatus"
        let randomized = self.attributionTypeFactory.mangledAuthStatusPropertyName

        expect { randomized.rot13() }.to(equal(expected))
    }
}
