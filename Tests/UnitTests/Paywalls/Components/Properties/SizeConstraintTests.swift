//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SizeConstraintTests.swift
//
//  Created by Jacob Zivan Rakidzich on 7/15/26.

@_spi(Internal) @testable import RevenueCat
import XCTest

final class SizeConstraintTests: TestCase {

    func test_decoding() throws {
        let data = try JsonLoader.data(for: "SizeConstraints", in: "../JSON")
        let sizes = try JSONDecoder().decode(Sizes.self, from: data)

        XCTAssertEqual(sizes.fitFit, .init(width: .fit(nil), height: .fit(nil)))
        XCTAssertEqual(sizes.fillFill, .init(width: .fill, height: .fill))
        XCTAssertEqual(sizes.fitFill, .init(width: .fit(2), height: .fill))
        XCTAssertEqual(sizes.fillFit, .init(width: .fill, height: .fit(2)))
    }
}

struct Sizes: Codable {
    let fitFit: PaywallComponent.Size
    let fillFill: PaywallComponent.Size
    let fitFill: PaywallComponent.Size
    let fillFit: PaywallComponent.Size

    enum CodingKeys: String, CodingKey {
        case fitFit = "fit_fit"
        case fillFill = "fill_fill"
        case fitFill = "fit_withDefault_fill"
        case fillFit = "fill_fit_withDefault"
    }
}
