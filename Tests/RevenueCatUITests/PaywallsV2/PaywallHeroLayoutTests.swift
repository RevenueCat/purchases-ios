//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) @testable import RevenueCat
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

    func testTextPromoVisibilityUsesSignedOfferInsteadOfOptimisticEligibility() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .promoOffer,
            .promoOfferCondition(operator: .equals, value: true),
            .promoOfferCondition(operator: .equals, value: false)
        ]
        for condition in conditions {
            for visible in [false, true] {
                for promoOffer in [nil, self.promoOffer] {
                    let stack = try self.makeStack([
                        .text(.init(
                            visible: visible, text: "text", color: .init(light: .hex("#000000")),
                            overrides: [.init(extendedConditions: [condition], properties: .init(visible: !visible))]
                        )),
                        self.image()
                    ])
                    guard case .text(let model) = stack.viewModels[0] else { return XCTFail("Expected text") }
                    // Subscription history can make optimistic eligibility true without a signed offer.
                    let layout = PaywallHeroLayoutResolver(
                        state: .default, condition: .compact,
                        isEligibleForIntroOffer: false, isEligibleForPromoOffer: true,
                        textPromoOffer: promoOffer,
                        conditionContext: ConditionContext(), discardRules: false,
                        eligibilityForPackage: { _ in (intro: false, promo: false) }
                    ).resolve(stack)
                    var renderedVisible: Bool?
                    _ = model.styles(
                        state: .default, condition: .compact, selectedPackageId: nil,
                        packageContext: .init(package: nil, variableContext: .init(packages: [])),
                        isEligibleForIntroOffer: false, promoOffer: promoOffer
                    ) { style in
                        renderedVisible = style.visible
                        return Color.clear
                    }
                    let textIsVisible = try XCTUnwrap(renderedVisible)
                    XCTAssertEqual(
                        layout.heroIdentifier != nil, !textIsVisible, "\(condition), base visible: \(visible)"
                    )
                    XCTAssertEqual(layout.exemptChildIndicesByStack[ObjectIdentifier(stack)], textIsVisible ? nil : 1)
                }
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

    func testHorizontalHeroRequiresOnlyOneVisibleChild() throws {
        let row = PaywallComponent.stack(.init(
            components: [self.image(), .text(.init(
                visible: false, text: "text", color: .init(light: .hex("#000000")),
                overrides: [.init(
                    extendedConditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
                    properties: .init(visible: true)
                )]
            ))],
            dimension: .horizontal(.top, .start)
        ))
        let stack = try self.makeStack([.stack(.init(visible: false, components: [])), row, self.image()])
        for width: CGFloat in [400, 900, 400] {
            let layout = self.resolve(stack, width: width)
            XCTAssertEqual(layout.heroIdentifier != nil, width < 700)
            XCTAssertEqual(layout.exemptChildIndicesByStack[ObjectIdentifier(stack)], width < 700 ? 1 : nil)
        }
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
            textPromoOffer: nil,
            conditionContext: ConditionContext(stateValues: stateValues), discardRules: false,
            eligibilityForPackage: { _ in (intro: false, promo: false) }
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

    func testSelectedPackageVisibilityMatchesPackageRenderer() throws {
        let package = TestData.monthlyPackage
        for visible in [false, true] {
            let component = PaywallComponent.package(.init(
                packageID: package.identifier, isSelectedByDefault: false, visible: visible,
                applePromoOfferProductCode: nil, stack: .init(components: [self.text]),
                overrides: [.init(conditions: [.selected], properties: .init(visible: !visible))]
            ))
            let stack = try self.makeStack([component, self.image()], packages: [package])
            guard case .package(let model) = stack.viewModels[0] else { return XCTFail("Expected package") }
            for selected in [false, true] {
                let selectedID = selected ? package.identifier : nil
                let renderedVisible = model.visible(
                    state: selected ? .selected : .default, condition: .compact,
                    isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
                    selectedPackageId: selectedID, customVariables: [:]
                )
                let layout = self.resolve(stack, context: ConditionContext(selectedPackageId: selectedID))
                XCTAssertEqual(layout.heroIdentifier != nil, !renderedVisible)
            }
        }
    }

    func testCompositeStateRulesMatchRendererVisibilityInBothDirections() throws {
        for visible in [false, true] {
            for component in self.compositesWithStateRule(visible: visible) {
                let stack = try self.makeStack([component, self.image()], packages: [TestData.monthlyPackage])
                let renderedVisible = try self.renderedCompositeVisibility(stack.viewModels[0])
                XCTAssertEqual(renderedVisible, visible)
                for context in [
                    ConditionContext(stateValues: ["toggle": .bool(true)]),
                    ConditionContext(stateDefaults: ["toggle": .bool(true)])
                ] {
                    let layout = self.resolve(stack, context: context)
                    XCTAssertEqual(layout.heroIdentifier != nil, !renderedVisible, "\(component)")
                }
            }
        }
    }

    func testMissingPackageDoesNotPreventHeroBleed() throws {
        let stack = try self.makeStack([
            .package(.init(
                packageID: "missing", isSelectedByDefault: false, applePromoOfferProductCode: nil,
                stack: .init(components: [self.text])
            )),
            self.image()
        ])
        XCTAssertNotNil(self.resolve(stack).heroIdentifier)
    }

    func testPackageUsesItsOwnIntroAndPromoEligibility() throws {
        let package = TestData.monthlyPackage
        let selectedPackage = TestData.annualPackage
        for condition in [PaywallComponent.ExtendedCondition.introOffer, .promoOffer] {
            for eligible in [false, true] {
                let stack = try self.makeStack([
                    .package(.init(
                        packageID: package.identifier, isSelectedByDefault: false, visible: false,
                        applePromoOfferProductCode: nil, stack: .init(components: [self.text]),
                        overrides: [.init(extendedConditions: [condition], properties: .init(visible: true))]
                    )),
                    self.image()
                ], packages: [package, selectedPackage])
                guard case .package(let model) = stack.viewModels[0] else { return XCTFail("Expected package") }
                let layout = PaywallHeroLayoutResolver(
                    state: .default, condition: .compact,
                    isEligibleForIntroOffer: !eligible, isEligibleForPromoOffer: !eligible,
                    textPromoOffer: nil,
                    conditionContext: ConditionContext(selectedPackageId: selectedPackage.identifier),
                    discardRules: false,
                    eligibilityForPackage: { candidate in
                        XCTAssertEqual(candidate.identifier, package.identifier)
                        return (intro: eligible, promo: eligible)
                    }
                ).resolve(stack)
                let renderedVisible = model.visible(
                    state: .default, condition: .compact,
                    isEligibleForIntroOffer: eligible, isEligibleForPromoOffer: eligible,
                    selectedPackageId: selectedPackage.identifier, customVariables: [:]
                )
                XCTAssertEqual(layout.heroIdentifier != nil, !renderedVisible)
            }
        }
    }

    func testMediaRetainsOptimisticPromoEligibilityWithoutSignedOffer() throws {
        let stack = try self.makeStack([self.image(overrides: [
            .init(conditions: [.promoOffer], properties: .init(visible: false))
        ])])
        let layout = PaywallHeroLayoutResolver(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: true,
            textPromoOffer: nil, conditionContext: ConditionContext(), discardRules: false,
            eligibilityForPackage: { _ in (intro: false, promo: false) }
        ).resolve(stack)
        XCTAssertNil(layout.heroIdentifier)
    }

    private var promoOffer: PromotionalOffer {
        PromotionalOffer(
            discount: MockStoreProductDiscount(
                offerIdentifier: "promo", currencyCode: "USD", price: 1, localizedPriceString: "$1.00",
                paymentMode: .payAsYouGo, subscriptionPeriod: .init(value: 1, unit: .month),
                numberOfPeriods: 1, type: .promotional
            ),
            signedData: .init(
                identifier: "promo", keyIdentifier: "key", nonce: UUID(), signature: "signature", timestamp: 1234
            )
        )
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
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>? = nil,
        packages: [Package] = []
    ) throws -> StackComponentViewModel {
        var factory = ViewModelFactory()
        return try factory.toRootViewModel(
            componentsConfig: .init(
                stack: .init(components: components, dimension: dimension, overrides: overrides),
                stickyFooter: nil, background: .color(.init(light: .hex("#FFFFFF")))
            ),
            offering: .init(
                identifier: "hero-test", serverDescription: "", availablePackages: packages, webCheckoutUrl: nil
            ),
            localizationProvider: .init(locale: .current, localizedStrings: ["text": .string("Text")]),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        ).stackViewModel
    }

    private func resolve(
        _ stack: StackComponentViewModel, width: CGFloat = 400, context: ConditionContext? = nil
    ) -> PaywallHeroLayout {
        return PaywallHeroLayoutResolver(
            state: .default, condition: .compact,
            isEligibleForIntroOffer: false, isEligibleForPromoOffer: false,
            textPromoOffer: nil,
            conditionContext: context ?? ConditionContext(windowSize: CGSize(width: width, height: 800)),
            discardRules: false,
            eligibilityForPackage: { _ in (intro: false, promo: false) }
        ).resolve(stack)
    }

    private func compositesWithStateRule(visible: Bool) -> [PaywallComponent] {
        let conditions = [PaywallComponent.ExtendedCondition.state(
            operator: .equals, name: "toggle", value: .bool(true)
        )]
        let content = PaywallComponent.StackComponent(components: [self.text])
        return [
            .button(.init(
                visible: visible, action: .restorePurchases, stack: content,
                overrides: [.init(extendedConditions: conditions, properties: .init(visible: !visible))]
            )),
            .package(.init(
                packageID: TestData.monthlyPackage.identifier, isSelectedByDefault: false, visible: visible,
                applePromoOfferProductCode: nil, stack: content,
                overrides: [.init(extendedConditions: conditions, properties: .init(visible: !visible))]
            )),
            .carousel(.init(
                visible: visible, pages: [content],
                overrides: [.init(extendedConditions: conditions, properties: .init(visible: !visible))]
            )),
            .tabs(.init(
                visible: visible, control: .init(type: .buttons, stack: .init(components: [])),
                tabs: [.init(id: "tab", stack: content)],
                overrides: [.init(extendedConditions: conditions, properties: .init(visible: !visible))]
            )),
            .timeline(.init(
                visible: visible, iconAlignment: nil, itemSpacing: nil, textSpacing: nil, columnGutter: nil,
                size: .init(width: .fill, height: .fit(nil)), padding: .zero, margin: .zero, items: [],
                overrides: [.init(extendedConditions: conditions, properties: .init(
                    visible: !visible, iconAlignment: nil, itemSpacing: nil, textSpacing: nil,
                    columnGutter: nil, size: nil, padding: nil, margin: nil
                ))]
            ))
        ]
    }

    private func renderedCompositeVisibility(_ viewModel: PaywallComponentViewModel) throws -> Bool {
        let visible: (ComponentViewState, ScreenCondition, Bool, Bool, String?,
                      [String: CustomVariableValue], CGSize?) -> Bool
        switch viewModel {
        case .button(let model): visible = model.visible
        case .package(let model): visible = model.visible
        case .carousel(let model): visible = model.visible
        case .tabs(let model): visible = model.visible
        case .timeline(let model): visible = model.visible
        default: throw NSError(domain: "Expected composite component", code: 1)
        }
        return visible(.default, .compact, false, false, nil, [:], nil)
    }

}

#endif
