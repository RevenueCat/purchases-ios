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

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallHeroLayoutTests: TestCase {

    func testHiddenSideDoesNotChangeHeroAcrossResizing() throws {
        let side = PaywallComponent.stack(.init(
            visible: false,
            components: [self.image(width: .fixed(160))],
            overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                properties: .init(visible: true)
            )]
        ))
        let stack = try self.makeStack([.fallbackHeader, side, self.image()])
        let heroIdentifier = stack.viewModels[1].nativeMediaIdentifier
        for width: CGFloat in [400, 900, 400] {
            let layout = self.resolve(stack, width: width)
            XCTAssertEqual(layout.heroIdentifier, width < 700 ? heroIdentifier : nil)
            XCTAssertEqual(layout.exemptChildIndicesByStack[ObjectIdentifier(stack)], width < 700 ? 1 : nil)
        }
    }

    func testTextUsesResolvedVisibilityInBothDirections() throws {
        for visible in [false, true] {
            let text = PaywallComponent.text(.init(
                visible: visible, text: "text", color: .init(light: .hex("#000000")),
                overrides: [.init(
                    extendedConditions: [.windowWidth(operator: .lessThan, value: 700)],
                    properties: .init(visible: !visible)
                )]
            ))
            let stack = try self.makeStack([text, self.image()])
            for width: CGFloat in [400, 900] {
                let textIsVisible = width < 700 ? !visible : visible
                let layout = self.resolve(stack, width: width)
                XCTAssertEqual(layout.heroIdentifier != nil, !textIsVisible)
                XCTAssertEqual(layout.exemptChildIndicesByStack[ObjectIdentifier(stack)], textIsVisible ? nil : 1)
            }
        }
    }

    func testNestedHeroInsetsOnlyItsOverlappingSiblingsAtEachAncestor() throws {
        let hidden = PaywallComponent.stack(.init(visible: false, components: []))
        let nestedHero = PaywallComponent.stack(.init(
            components: [self.image(), self.text], dimension: .zlayer(.top)
        ))
        let wrapper = PaywallComponent.stack(.init(components: [hidden, nestedHero]))
        let unrelatedCard = PaywallComponent.stack(.init(
            components: [self.image(), self.text], dimension: .zlayer(.top)
        ))
        let stack = try self.makeStack([hidden, wrapper, self.text, unrelatedCard])
        guard case .stack(let wrapperModel) = stack.viewModels[1],
              case .stack(let heroModel) = wrapperModel.viewModels[1] else {
            return XCTFail("Expected nested hero stacks")
        }
        let layout = self.resolve(stack)
        XCTAssertEqual(layout.heroIdentifier, heroModel.viewModels[0].nativeMediaIdentifier)
        XCTAssertEqual(layout.exemptChildIndicesByStack, [
            ObjectIdentifier(stack): 1, ObjectIdentifier(heroModel): 0
        ])
    }

    func testVisibleNonMediaAndEmptyStacksStopHeroSearch() throws {
        let leadingComponents: [PaywallComponent] = [
            self.text,
            self.image(width: .fixed(200)),
            .stack(.init(components: [])),
            .stack(.init(components: [self.text, self.image()])),
            .stack(.init(components: [.stack(.init(visible: false, components: [self.image()]))]))
        ]
        for leading in leadingComponents {
            let stack = try self.makeStack([leading, self.image()])
            let layout = self.resolve(stack)
            XCTAssertNil(layout.heroIdentifier)
            XCTAssertTrue(layout.exemptChildIndicesByStack.isEmpty)
        }
    }

    func testMediaVisibilityAndWidthOverridesUpdateHeroEligibility() throws {
        for properties in [
            PaywallComponent.PartialImageComponent(visible: false),
            .init(size: .init(width: .fixed(200), height: .fixed(240)))
        ] {
            let stack = try self.makeStack([self.image(overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                properties: properties
            )])])
            XCTAssertNotNil(self.resolve(stack, width: 400).heroIdentifier)
            XCTAssertNil(self.resolve(stack, width: 900).heroIdentifier)
        }
    }

    func testResolvedDimensionsDetermineOverlayOwnership() throws {
        let stack = try self.makeStack(
            [self.image(), self.text], dimension: .vertical(.leading, .start),
            overrides: [.init(
                extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                properties: .init(dimension: .zlayer(.top))
            )]
        )
        XCTAssertNotNil(self.resolve(stack, width: 400).heroIdentifier)
        XCTAssertTrue(self.resolve(stack, width: 400).exemptChildIndicesByStack.isEmpty)
        XCTAssertEqual(self.resolve(stack, width: 900).exemptChildIndicesByStack[ObjectIdentifier(stack)], 0)
    }

    func testRuleContextAndDiscardPolicyMatchRendering() throws {
        let text = PaywallComponent.text(.init(
            visible: false, text: "text", color: .init(light: .hex("#000000")),
            overrides: [.init(
                extendedConditions: [
                    .selectedPackage(operator: .in, packages: ["annual"]),
                    .variable(operator: .equals, variable: "show", value: .bool(true)),
                    .state(operator: .equals, name: "step", value: .int(2)),
                    .introOfferCondition(operator: .equals, value: true)
                ],
                properties: .init(visible: true)
            )]
        ))
        let stack = try self.makeStack([text, self.image()])
        let context = ConditionContext(
            selectedPackageId: "annual", customVariables: ["show": .bool(true)],
            stateValues: ["step": .int(2)], windowSize: CGSize(width: 400, height: 800)
        )
        for discardRules in [false, true] {
            let layout = PaywallHeroLayoutResolver(
                state: .default, condition: .compact,
                isEligibleForIntroOffer: true, isEligibleForPromoOffer: false,
                conditionContext: context, discardRules: discardRules
            ).resolve(stack)
            XCTAssertEqual(layout.heroIdentifier != nil, discardRules)
        }
    }

    func testVideoStateRulesAgreeWithRendering() throws {
        let component = PaywallComponent.video(.init(
            source: .init(light: .init(
                width: 400, height: 240, url: URL(string: "https://revenuecat.com/video.mp4")!,
                checksum: nil, urlLowRes: nil, checksumLowRes: nil
            )),
            overrides: [.init(
                extendedConditions: [.state(operator: .equals, name: "hide", value: .bool(true))],
                properties: .init(visible: false)
            )]
        ))
        let stack = try self.makeStack([component, self.text])
        guard case .video(let video) = stack.viewModels[0] else { return XCTFail("Expected video") }
        let stateValues: [String: PaywallComponent.ConditionValue] = ["hide": .bool(true)]
        let layout = PaywallHeroLayoutResolver(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(stateValues: stateValues), discardRules: false
        ).resolve(stack)
        var renderedVisible: Bool?
        _ = video.styles(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            selectedPackageId: nil, customVariables: [:], stateValues: stateValues, colorScheme: .light
        ) { style in
            renderedVisible = style.visible
            return Color.clear
        }
        XCTAssertEqual(renderedVisible, false)
        XCTAssertNil(layout.heroIdentifier)
        XCTAssertNotNil(self.resolve(stack).heroIdentifier)
    }

    func testWebViewVisibilityRulesUpdateHeroEligibility() throws {
        let stack = try self.makeStack([
            .webView(.init(
                id: "web-hero", protocolVersion: PaywallComponent.WebViewComponent.supportedProtocolVersion,
                url: "https://revenuecat.com", size: .init(width: .fill, height: .fixed(240)),
                overrides: [.init(
                    extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                    properties: .init(visible: false)
                )]
            )),
            self.text
        ])
        XCTAssertNotNil(self.resolve(stack, width: 400).heroIdentifier)
        XCTAssertNil(self.resolve(stack, width: 900).heroIdentifier)
    }

    private var text: PaywallComponent {
        .text(.init(text: "text", color: .init(light: .hex("#000000"))))
    }

    private func image(
        width: PaywallComponent.SizeConstraint = .fill,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialImageComponent>? = nil
    ) -> PaywallComponent {
        let url = URL(string: "https://revenuecat.com/image.heic")!
        return .image(.init(
            source: .init(light: .init(width: 400, height: 240, original: url, heic: url, heicLowRes: url)),
            size: .init(width: width, height: .fixed(240)), overrides: overrides
        ))
    }

    private func makeStack(
        _ components: [PaywallComponent],
        dimension: PaywallComponent.Dimension = .zlayer(.top),
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>? = nil
    ) throws -> StackComponentViewModel {
        let factory = ViewModelFactory()
        return try factory.toStackViewModel(
            component: .init(components: components, dimension: dimension, overrides: overrides),
            packageValidator: factory.packageValidator, purchaseButtonCollector: nil,
            localizationProvider: .init(locale: .current, localizedStrings: ["text": .string("Text")]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            offering: .init(identifier: "hero-test", serverDescription: "", availablePackages: [], webCheckoutUrl: nil),
            colorScheme: .light
        )
    }

    private func resolve(_ stack: StackComponentViewModel, width: CGFloat = 400) -> PaywallHeroLayout {
        return PaywallHeroLayoutResolver(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(windowSize: CGSize(width: width, height: 800)), discardRules: false
        ).resolve(stack)
    }

}

#endif
