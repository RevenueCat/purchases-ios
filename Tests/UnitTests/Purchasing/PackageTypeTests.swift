//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageTypeTests.swift
//
//  Created by Nacho Soto on 7/12/23.

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PackageTypeTests: TestCase {

    func testCodable() throws {
        for type in PackageType.allCases where type != .custom {
            do {
                let encoded = try Data(type: type).encodeAndDecode()

                expect(encoded.type).to(
                    equal(type),
                    description: "Failed encoding '\(type.debugDescription)'"
                )
            } catch {
                fail("Failed encoding '\(type.debugDescription)': \(error)")
            }
        }
    }

    func testEncodingCustom() throws {
        // We don't have a way to tell this appart from `.unknown`
        expect(try Data(type: .custom).encodeAndDecode().type) == .unknown
    }

}

private extension PackageTypeTests {

    /// iOS 12 does not allow literalls as root types, so we test encoding it inside of a dictionary
    struct Data: Codable {
        var type: PackageType
    }

}
