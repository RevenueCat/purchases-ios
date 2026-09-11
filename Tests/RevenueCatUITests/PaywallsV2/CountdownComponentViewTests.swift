//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CountdownComponentViewTests.swift
//

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest
// swiftlint:disable force_try

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CountdownComponentViewTests: TestCase {

    // MARK: - Decoding

    func testCodableRoundTripWithVisibleOverride() throws {
        let jsonData = Data("""
        {
          "type": "countdown",
          "visible": true,
          "style": { "type": "date", "date": "2035-01-01T00:00:00Z" },
          "count_from": "days",
          "countdown_stack": \(Self.stackJSON),
          "overrides": [
            {
              "conditions": [{ "type": "selected" }],
              "properties": { "visible": false }
            }
          ]
        }
        """.utf8)

        let countdown = try JSONDecoder.default
            .decode(PaywallComponent.CountdownComponent.self, from: jsonData)

        XCTAssertEqual(countdown.visible, true)
        XCTAssertEqual(countdown.overrides?.count, 1)
        XCTAssertEqual(countdown.overrides?.first?.conditions, [.selected])
        XCTAssertEqual(countdown.overrides?.first?.properties.visible, false)

        let reencoded = try JSONEncoder.default.encode(countdown)
        let countdown2 = try JSONDecoder.default
            .decode(PaywallComponent.CountdownComponent.self, from: reencoded)

        XCTAssertEqual(countdown, countdown2)
    }

    func testViewModelFactoryPreservesOverrides() throws {
        let result = try Self.viewModel(decodedFrom: """
        {
          "type": "countdown",
          "style": { "type": "date", "date": "2035-01-01T00:00:00Z" },
          "count_from": "days",
          "countdown_stack": \(Self.stackJSON),
          "overrides": [
            {
              "conditions": [{ "type": "selected" }],
              "properties": { "visible": false }
            }
          ]
        }
        """)

        guard case .countdown(let built) = result else {
            return XCTFail("Expected .countdown view model")
        }

        // Default state keeps the base (visible) value; the selected override only applies when selected.
        XCTAssertTrue(Self.resolvedVisible(built))
        XCTAssertFalse(Self.resolvedVisible(built, state: .selected))
    }

    // MARK: - Visibility resolution

    func testVisibleDefaultsToTrue() {
        XCTAssertTrue(Self.resolvedVisible(Self.makeViewModel()))
        XCTAssertFalse(Self.resolvedVisible(Self.makeViewModel(visible: false)))
    }

    func testVisibleAppliesSelectedVisibilityOverride() {
        let viewModel = Self.makeViewModel(
            visible: false,
            overrides: [
                .init(conditions: [.selected], properties: .init(visible: true))
            ]
        )

        // Default state keeps the base (hidden) value.
        XCTAssertFalse(Self.resolvedVisible(viewModel))
        // Selected state applies the override and shows the countdown.
        XCTAssertTrue(Self.resolvedVisible(viewModel, state: .selected))
    }

    func testVisibleAppliesSizeClassVisibilityOverride() {
        let viewModel = Self.makeViewModel(
            visible: true,
            overrides: [
                .init(conditions: [.expanded], properties: .init(visible: false))
            ]
        )

        // Compact keeps the base (visible) value; expanded hides it.
        XCTAssertTrue(Self.resolvedVisible(viewModel, condition: .compact))
        XCTAssertFalse(Self.resolvedVisible(viewModel, condition: .expanded))
    }

    func testVisibleLaterMatchingOverrideWins() {
        let viewModel = Self.makeViewModel(
            visible: true,
            overrides: [
                .init(conditions: [.selected], properties: .init(visible: true)),
                .init(conditions: [.selected], properties: .init(visible: false))
            ]
        )

        // Both overrides match the selected state; combine ordering means the later one wins.
        XCTAssertFalse(Self.resolvedVisible(viewModel, state: .selected))
    }

    func testVisibleAppliesWindowWidthVisibilityOverride() {
        let viewModel = Self.makeViewModel(
            visible: true,
            overrides: [
                .init(
                    extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                    properties: .init(visible: false)
                )
            ]
        )

        // Unknown window size never matches; narrow doesn't match; wide hides the countdown.
        XCTAssertTrue(Self.resolvedVisible(viewModel, windowSize: nil))
        XCTAssertTrue(Self.resolvedVisible(viewModel, windowSize: CGSize(width: 390, height: 844)))
        XCTAssertFalse(Self.resolvedVisible(viewModel, windowSize: CGSize(width: 904, height: 640)))
    }

    // MARK: - Rule discarding

    func testDiscardRulesStripsRuleBasedCountdownOverrides() {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialCountdownComponent> = [
            .init(
                extendedConditions: [.selectedPackage(operator: .in, packages: ["monthly"])],
                properties: .init(visible: false)
            )
        ]

        func visibleWhenMonthlySelected(discardRules: Bool) -> Bool {
            Self.makeViewModel(
                visible: true,
                overrides: overrides,
                discardRules: discardRules
            ).visible(
                state: .default,
                condition: .compact,
                isEligibleForIntroOffer: false,
                isEligibleForPromoOffer: false,
                selectedPackageId: "monthly",
                customVariables: [:]
            )
        }

        // Honored: selecting the package hides the countdown.
        XCTAssertFalse(visibleWhenMonthlySelected(discardRules: false))
        // Discarded: the rule is stripped, so the base (visible) value stands.
        XCTAssertTrue(visibleWhenMonthlySelected(discardRules: true))
    }

    // MARK: - CountdownState

    @MainActor
    func testStartRefreshesStateAfterDeadlinePassesWhileStopped() async throws {
        let state = CountdownState(
            targetDate: Date().addingTimeInterval(0.1),
            countFrom: .minutes
        )
        state.start()
        XCTAssertFalse(state.hasEnded)
        state.stop()

        // Let the deadline pass while the countdown is hidden (stopped).
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertFalse(state.hasEnded)

        // Re-showing must reflect the current time immediately, without waiting for a timer tick.
        state.start()
        XCTAssertTrue(state.hasEnded)
        XCTAssertEqual(state.countdownTime.seconds, 0)
    }

    // MARK: - Helpers

    private static let stackJSON = """
    {
        "type": "stack",
        "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
        "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
        "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
        "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
        "components": []
    }
    """

    /// Decodes a component from `json` and runs it through the real `ViewModelFactory`, exercising the
    /// full decode-to-view-model seam.
    private static func viewModel(decodedFrom json: String) throws -> PaywallComponentViewModel {
        let component = try JSONDecoder.default.decode(PaywallComponent.self, from: Data(json.utf8))

        return try ViewModelFactory().toViewModel(
            component: component,
            packageValidator: PackageValidator(),
            offering: .init(
                identifier: "test_offering",
                serverDescription: "Test Offering",
                metadata: [:],
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        )
    }

    private static func makeViewModel(
        visible: Bool? = nil,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialCountdownComponent>? = nil,
        discardRules: Bool = false
    ) -> CountdownComponentViewModel {
        let stack = PaywallComponent.StackComponent(components: [])
        return CountdownComponentViewModel(
            component: .init(
                visible: visible,
                style: .date(Date(timeIntervalSince1970: 0)),
                countFrom: .days,
                countdownStack: stack,
                overrides: overrides
            ),
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            countdownStackViewModel: try! .init(
                component: stack,
                localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: [:]),
                colorScheme: .light
            ),
            endStackViewModel: nil,
            fallbackStackViewModel: nil,
            discardRules: discardRules
        )
    }

    private static func resolvedVisible(
        _ viewModel: CountdownComponentViewModel,
        state: ComponentViewState = .default,
        condition: ScreenCondition = .compact,
        windowSize: CGSize? = nil
    ) -> Bool {
        viewModel.visible(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            windowSize: windowSize
        )
    }

}

#endif
