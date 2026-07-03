//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentTests.swift
//
//  Created by Claude on 7/3/2026.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

#if !os(tvOS) // For Paywalls V2

class PackageComponentCodableTests: TestCase {

    let jsonStringDefaultStack = """
    {
        "type": "stack",
        "dimension": {
            "type": "vertical",
            "alignment": "center",
            "distribution": "start"
        },
        "size": {
            "width": { "type": "fill" },
            "height": { "type": "fill" }
        },
        "padding": {
            "top": 0,
            "bottom": 0,
            "leading": 0,
            "trailing": 0
        },
        "margin": {
            "top": 0,
            "bottom": 0,
            "leading": 0,
            "trailing": 0
        },
        "components": []
    }
    """

    func testDecodesId() throws {
        let jsonString = """
        {
            "type": "package",
            "packageId": "$rc_annual",
            "isSelectedByDefault": true,
            "id": "kQ_qY2xSNz",
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPackage = try JSONDecoder.default.decode(PaywallComponent.PackageComponent.self, from: jsonData)

        expect(decodedPackage.id) == "kQ_qY2xSNz"
    }

    func testIdIsNilWhenAbsent() throws {
        let jsonString = """
        {
            "type": "package",
            "packageId": "$rc_annual",
            "isSelectedByDefault": true,
            "stack": \(jsonStringDefaultStack)
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let decodedPackage = try JSONDecoder.default.decode(PaywallComponent.PackageComponent.self, from: jsonData)

        expect(decodedPackage.id).to(beNil())
    }

    func testIdRoundTripsThroughEncoding() throws {
        let jsonString = """
        {
            "type": "package",
            "packageId": "$rc_annual",
            "isSelectedByDefault": true,
            "id": "kQ_qY2xSNz",
            "stack": \(jsonStringDefaultStack)
        }
        """
        let original = try JSONDecoder.default.decode(
            PaywallComponent.PackageComponent.self,
            from: jsonString.data(using: .utf8)!
        )

        let encoded = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(PaywallComponent.PackageComponent.self, from: encoded)

        expect(decoded.id) == "kQ_qY2xSNz"
        expect(decoded) == original
    }

    func testTwoPackagesWithSamePackageIDButDifferentIdAreNotEqual() throws {
        let first = PaywallComponent.PackageComponent(
            packageID: "$rc_annual",
            isSelectedByDefault: true,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            id: "component-a"
        )
        let second = PaywallComponent.PackageComponent(
            packageID: "$rc_annual",
            isSelectedByDefault: true,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [],
                dimension: .vertical(.center, .start),
                size: .init(width: .fill, height: .fill)
            ),
            id: "component-b"
        )

        XCTAssertNotEqual(first, second)
    }

}

#endif
