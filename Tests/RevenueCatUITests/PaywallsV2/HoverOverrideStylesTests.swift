//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HoverOverrideStylesTests.swift
//
//  Created by Josh Holtz on 9/2/26.

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class HoverOverrideStylesTests: TestCase {

    // MARK: - Stack

    func testStackHoverOverride_AppliedOnlyWhenHovered() throws {
        let viewModel = try makeStackViewModel(overrides: [
            .init(extendedConditions: [.hover], properties: .init(visible: false))
        ])

        let base = viewModel.styles(
            state: .default,
            condition: .compact,
            isHovered: false,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            colorScheme: .light
        )
        let hovered = viewModel.styles(
            state: .default,
            condition: .compact,
            isHovered: true,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            colorScheme: .light
        )

        expect(base.visible).to(beTrue())
        expect(hovered.visible).to(beFalse())
    }

    func testStackHasHoverOverride() throws {
        let withHover = try makeStackViewModel(overrides: [
            .init(extendedConditions: [.hover], properties: .init(visible: false))
        ])
        let withoutHover = try makeStackViewModel(overrides: [
            .init(extendedConditions: [.selected], properties: .init(visible: false))
        ])

        expect(withHover.hasHoverOverride).to(beTrue())
        expect(withoutHover.hasHoverOverride).to(beFalse())
    }

    // MARK: - Text

    @MainActor
    func testTextHoverOverride_AppliedOnlyWhenHovered() throws {
        let viewModel = try makeTextViewModel(overrides: [
            .init(extendedConditions: [.hover], properties: .init(visible: false))
        ])

        expect(try self.capturedVisible(from: viewModel, isHovered: false)).to(beTrue())
        expect(try self.capturedVisible(from: viewModel, isHovered: true)).to(beFalse())
    }

    func testTextHasHoverOverride() throws {
        let withHover = try makeTextViewModel(overrides: [
            .init(extendedConditions: [.hover], properties: .init(visible: false))
        ])
        let withoutHover = try makeTextViewModel(overrides: [
            .init(extendedConditions: [.selected], properties: .init(visible: false))
        ])

        expect(withHover.hasHoverOverride).to(beTrue())
        expect(withoutHover.hasHoverOverride).to(beFalse())
    }

    // MARK: - Helpers

    private static let black = PaywallComponent.ColorScheme(
        light: .hex("#000000")
    )

    private static func createUIConfigProvider() throws -> UIConfigProvider {
        let json = """
        {
          "app": {
            "colors": {},
            "fonts": {}
          },
          "localizations": {},
          "variable_config": {
            "variable_compatibility_map": {},
            "function_compatibility_map": {}
          }
        }
        """
        let jsonData = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let uiConfig = try decoder.decode(UIConfig.self, from: jsonData)
        return UIConfigProvider(uiConfig: uiConfig)
    }

    private func makeStackViewModel(
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>
    ) throws -> StackComponentViewModel {
        StackComponentViewModel(
            component: PaywallComponent.StackComponent(
                components: [],
                overrides: overrides
            ),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: try Self.createUIConfigProvider()
        )
    }

    private func makeTextViewModel(
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialTextComponent>
    ) throws -> TextComponentViewModel {
        let localizations: PaywallComponent.LocalizationDictionary = [
            "text_lid": .string("Hello")
        ]

        return try TextComponentViewModel(
            localizationProvider: LocalizationProvider(locale: .current, localizedStrings: localizations),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: PaywallComponent.TextComponent(
                text: "text_lid",
                color: Self.black,
                overrides: overrides
            )
        )
    }

    @MainActor
    private func capturedVisible(from viewModel: TextComponentViewModel, isHovered: Bool) throws -> Bool {
        var capturedVisible: Bool?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            isHovered: isHovered,
            selectedPackageId: nil,
            packageContext: PackageContext(package: nil, variableContext: .init()),
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedVisible = style.visible
            return EmptyView()
        }
        return try XCTUnwrap(capturedVisible)
    }

}

#endif
