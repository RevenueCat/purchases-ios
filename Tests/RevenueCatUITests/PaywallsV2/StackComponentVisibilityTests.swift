//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, *)
@MainActor
final class StackComponentVisibilityTests: TestCase {

    func testVerticalStackOnlySpacesVisibleChildren() throws {
        let viewModel = try Self.viewModel(dimension: .vertical(.center, .start))
        let view = StackComponentView(viewModel: viewModel, onDismiss: {})
            .previewRequiredPaywallsV2Properties()

        XCTAssertEqual(
            UIHostingController(rootView: view).sizeThatFits(in: .init(width: 100, height: 100)).height,
            30
        )
    }

    func testHorizontalStackOnlySpacesVisibleChildren() throws {
        let viewModel = try Self.viewModel(dimension: .horizontal(.center, .start))
        let view = StackComponentView(viewModel: viewModel, onDismiss: {})
            .previewRequiredPaywallsV2Properties()

        XCTAssertEqual(
            UIHostingController(rootView: view).sizeThatFits(in: .init(width: 100, height: 100)).width,
            30
        )
    }

    func testVisibilityOverrideRemovesChildSpacing() throws {
        let viewModel = try Self.viewModelWithVisibilityOverride(
            baseVisible: true,
            overrideVisible: false
        )
        let view = StackComponentView(viewModel: viewModel, onDismiss: {})
            .previewRequiredPaywallsV2Properties()
            .environment(\.customPaywallVariables, ["hide": .bool(true)])

        XCTAssertEqual(
            UIHostingController(rootView: view).sizeThatFits(in: .init(width: 100, height: 100)).height,
            10
        )
    }

    func testVisibilityOverrideRestoresChildAndSpacing() throws {
        let viewModel = try Self.viewModelWithVisibilityOverride(
            baseVisible: false,
            overrideVisible: true
        )
        let view = StackComponentView(viewModel: viewModel, onDismiss: {})
            .previewRequiredPaywallsV2Properties()
            .environment(\.customPaywallVariables, ["hide": .bool(true)])

        XCTAssertEqual(
            UIHostingController(rootView: view).sizeThatFits(in: .init(width: 100, height: 100)).height,
            30
        )
    }

    private static func viewModel(
        dimension: PaywallComponent.Dimension
    ) throws -> StackComponentViewModel {
        let visibleChild = PaywallComponent.stack(PaywallComponent.StackComponent(
            components: [],
            size: .init(width: .fixed(10), height: .fixed(10))
        ))
        let hiddenChild = PaywallComponent.stack(PaywallComponent.StackComponent(
            visible: false,
            components: [],
            size: .init(width: .fixed(10), height: .fixed(10))
        ))
        let component = PaywallComponent.StackComponent(
            components: [visibleChild, hiddenChild, visibleChild],
            dimension: dimension,
            size: .init(width: .fit(nil), height: .fit(nil)),
            spacing: 10
        )

        return try StackComponentViewModel(
            component: component,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            colorScheme: .light
        )
    }

    private static func viewModelWithVisibilityOverride(
        baseVisible: Bool,
        overrideVisible: Bool
    ) throws -> StackComponentViewModel {
        let size = PaywallComponent.Size(width: .fixed(10), height: .fixed(10))
        let conditionalChild = PaywallComponent.stack(PaywallComponent.StackComponent(
            visible: baseVisible,
            components: [],
            size: size,
            overrides: [
                .init(
                    extendedConditions: [
                        .variable(operator: .equals, variable: "hide", value: .bool(true))
                    ],
                    properties: .init(visible: overrideVisible)
                )
            ]
        ))
        let visibleChild = PaywallComponent.stack(PaywallComponent.StackComponent(components: [], size: size))
        let component = PaywallComponent.StackComponent(
            components: [conditionalChild, visibleChild],
            size: .init(width: .fit(nil), height: .fit(nil)),
            spacing: 10
        )

        return try StackComponentViewModel(
            component: component,
            localizationProvider: .init(locale: .current, localizedStrings: [:]),
            colorScheme: .light
        )
    }

}

#endif
