//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoredEventTests.swift
//
//  Created by Cesar de la Vega on 31/10/24.

import Foundation
import Nimble
@testable import RevenueCat

class StoredEventTests: TestCase {

    func testDecodingWithInvalidFeature() throws {
        let json = """
        {
            "event": {"some": "data"},
            "userId": "test-user",
            "feature": "invalid_feature"
        }
        """

        let event = try decode(json)
        expect(event.feature) == .paywalls
    }

    func testDecodingWithMissingFeature() throws {
        let json = """
        {
            "event": {"some": "data"},
            "userId": "test-user"
        }
        """

        let event = try decode(json)
        expect(event.feature) == .paywalls
    }

    private func decode(_ json: String) throws -> StoredEvent {
        return try JSONDecoder().decode(StoredEvent.self, from: Data(json.utf8))
    }
}
