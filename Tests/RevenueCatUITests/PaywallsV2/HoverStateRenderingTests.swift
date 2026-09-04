//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HoverStateRenderingTests.swift
//
//  Created by Josh Holtz on 9/2/26.

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)
import UIKit

/// Measures components hosted with the hover environment injected, asserting that the hover state
/// actually flows from the environment through the view into the resolved styles. Layout size is
/// compared because SwiftUI content is not reachable through UIKit subviews, and `drawHierarchy`
/// renders blank in unit tests.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class HoverStateRenderingTests: TestCase {

    func testTextHoverOverride_ChangesLayoutWhenHoverEnvironmentIsActive() throws {
        let viewModel = try Self.makeTextViewModel()

        let defaultHeight = Self.fittedHeight(TextComponentView(viewModel: viewModel), hovered: false)
        let hoveredHeight = Self.fittedHeight(TextComponentView(viewModel: viewModel), hovered: true)

        XCTAssertGreaterThan(defaultHeight, 0)
        XCTAssertGreaterThan(
            hoveredHeight,
            defaultHeight,
            "The .hover override bumps the font size, so the hovered text should measure taller."
        )
    }

    func testStackHoverOverrideVisibleFalse_ChangesLayoutWhenHoverEnvironmentIsActive() throws {
        let viewModel = try Self.makeStackViewModel()

        let defaultHeight = Self.fittedHeight(
            StackComponentView(viewModel: viewModel, onDismiss: {}), hovered: false
        )
        let hoveredHeight = Self.fittedHeight(
            StackComponentView(viewModel: viewModel, onDismiss: {}), hovered: true
        )

        XCTAssertGreaterThan(defaultHeight, 0)
        XCTAssertLessThan(
            hoveredHeight,
            defaultHeight,
            "A stack with a .hover override that hides should measure smaller when hovered."
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension HoverStateRenderingTests {

    static let localizations: PaywallComponent.LocalizationDictionary = [
        "id_1": .string("Hello"),
        "id_2": .string("Hovered")
    ]

    static func makeTextViewModel() throws -> TextComponentViewModel {
        return try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: Self.localizations
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            component: PaywallComponent.TextComponent(
                text: "id_1",
                color: .init(light: .hex("#000000")),
                overrides: [
                    .init(extendedConditions: [.hover], properties: .init(text: "id_2", fontSize: 40))
                ]
            )
        )
    }

    static func makeStackViewModel() throws -> StackComponentViewModel {
        let localizationProvider = LocalizationProvider(
            locale: Locale(identifier: "en_US"),
            localizedStrings: Self.localizations
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let factory = ViewModelFactory()

        return try factory.toStackViewModel(
            component: PaywallComponent.StackComponent(
                components: [
                    .text(PaywallComponent.TextComponent(
                        text: "id_1",
                        color: .init(light: .hex("#000000"))
                    ))
                ],
                overrides: [
                    .init(extendedConditions: [.hover], properties: .init(visible: false))
                ]
            ),
            packageValidator: factory.packageValidator,
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: Offering(
                identifier: "default",
                serverDescription: "",
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            colorScheme: .light
        )
    }

    static func fittedHeight<Content: View>(_ view: Content, hovered: Bool) -> CGFloat {
        let controller = UIHostingController(
            rootView: view
                .environmentObject(PackageContext(package: nil, variableContext: .init(packages: [])))
                .environmentObject(
                    IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
                )
                .environmentObject(
                    PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker())
                )
                .environment(\.componentHoverState, hovered)
                .environment(\.screenCondition, .compact)
                .environment(\.safeAreaInsets, EdgeInsets())
        )
        return controller.sizeThatFits(in: CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude)).height
    }

}

#endif
