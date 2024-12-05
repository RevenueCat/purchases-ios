//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponent.swift
//
//  Created by Josh Holtz on 10/26/24.

import Nimble
@testable import RevenueCat
import XCTest

#if PAYWALL_COMPONENTS

final class PartialComponentTests: TestCase {

    // Properties of full components that partials can't have
    static let ignoredProperties = ["type", "components", "overrides"]

    static let sampleURL = URL(string: "https://revenuecat.com")!

    // This should not need to test container components that HAVE a stack
    // The stack is where the partials will exist
    let componentPairs: [(Any, Any)] = [
        // TextComponent
        (PaywallComponent.TextComponent(
            text: "Test",
            fontFamily: "Arial",
            fontWeight: .bold,
            color: .init(light: "#000000"),
            backgroundColor: .init(light: "#FFFFFF"),
            padding: .init(top: 10, bottom: 10, leading: 10, trailing: 10),
            margin: .init(top: 5, bottom: 5, leading: 5, trailing: 5),
            textStyle: .title,
            horizontalAlignment: .leading
        ), PaywallComponent.PartialTextComponent()),

        // ImageComponent
        (PaywallComponent.ImageComponent(source: .init(
            light: .init(original: sampleURL,
                         heic: sampleURL,
                         heicLowRes: sampleURL))
        ), PaywallComponent.PartialImageComponent()),

        // StackComponent
        (PaywallComponent.StackComponent(components: []), PaywallComponent.PartialStackComponent())
    ]

    func testPartialTextComponentPropertiesMatchTextComponent() {
        for (full, partial) in componentPairs {

            let fullMirror = Mirror(reflecting: full)
            let partialMirror = Mirror(reflecting: partial)

            // Check that component properties exist on partial component and are optional
            for child in fullMirror.children {
                guard let label = child.label, !Self.ignoredProperties.contains(label) else { continue }

                guard let partialChild = partialMirror.children.first(where: { $0.label == label }) else {
                    XCTFail("\(type(of: partial)) is missing property: \(label)")
                    continue
                }

                XCTAssertTrue(
                    isOptional(partialChild.value),
                    "\(type(of: partial)) has \(label) is not optional"
                )
            }
        }
    }

    // Helper function to check if a value is optional
    private func isOptional(_ value: Any) -> Bool {
        let mirror = Mirror(reflecting: value)
        return mirror.displayStyle == .optional
    }

}

#endif
