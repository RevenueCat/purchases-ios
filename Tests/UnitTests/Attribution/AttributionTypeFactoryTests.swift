//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class AttributionTypeFactoryTests: TestCase {

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
        let randomized = ASIdManagerProxy.mangledIdentifierClassName

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
        let randomized = ASIdManagerProxy.mangledIdentifierPropertyName

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
        let randomized = TrackingManagerProxy.mangledTrackingClassName

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
        let randomized = TrackingManagerProxy.mangledAuthStatusPropertyName

        expect { randomized.rot13() }.to(equal(expected))
    }
}
