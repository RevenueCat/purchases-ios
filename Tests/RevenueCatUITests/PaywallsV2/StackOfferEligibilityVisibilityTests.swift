//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackOfferEligibilityVisibilityTests.swift
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StackOfferEligibilityVisibilityTests: TestCase {

    func testStackWithoutOfferConditionsDoesNotRedactWhileEligibilityLoads() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.selected], properties: .init(visible: false))
        ])

        expect(self.redacts(viewModel)).to(beFalse())
        expect(self.redacts(viewModel, state: .selected)).to(beFalse())
    }

    func testIntroOfferConditionRedactsWhileEligibilityLoads() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(viewModel)).to(beTrue())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testIntroOfferConditionDoesNotWaitForPromoEligibility() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: false,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testPromoOfferConditionDoesNotWaitForIntroEligibility() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.promoOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: true,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testStackWithBothOfferConditionsWaitsForTheCheckThatChangesVisibility() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false)),
            .init(conditions: [.promoOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: false,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beTrue())
        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: false,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beTrue())
        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testIntroOfferConditionRedactsWhetherTheStackEndsUpHiddenOrShown() {
        let shownForIntro = Self.makeViewModel(
            visible: false,
            overrides: [
                .init(conditions: [.introOffer], properties: .init(visible: true))
            ]
        )
        let hiddenForIntro = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(shownForIntro)).to(beTrue())
        expect(self.redacts(hiddenForIntro)).to(beTrue())
        expect(self.redacts(
            shownForIntro,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testIntroOfferSpacingOverrideDoesNotRedact() {
        let viewModel = Self.makeViewModel(
            visible: false,
            overrides: [
                .init(conditions: [.introOffer], properties: .init(visible: nil, spacing: 12))
            ]
        )

        expect(self.redacts(viewModel)).to(beFalse())
    }

    func testIntroOfferConditionIgnoresOverridesForAnotherScreenCondition() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(
                conditions: [.expanded, .introOffer],
                properties: .init(visible: false)
            )
        ])

        expect(self.redacts(viewModel, condition: .compact)).to(beFalse())
        expect(self.redacts(viewModel, condition: .expanded)).to(beTrue())
        expect(self.redacts(
            viewModel,
            condition: .compact,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testPromoIneligibleConditionRedactsWhileEligibilityLoads() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(
                extendedConditions: [.promoOfferCondition(operator: .equals, value: false)],
                properties: .init(visible: false)
            )
        ])

        expect(self.redacts(viewModel)).to(beTrue())
        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: false,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension StackOfferEligibilityVisibilityTests {

    func redacts(
        _ viewModel: StackComponentViewModel,
        state: ComponentViewState = .default,
        condition: ScreenCondition = .compact,
        isEligibleForIntroOffer: Bool = false,
        isEligibleForPromoOffer: Bool = false,
        isIntroOfferEligibilityLoading: Bool = true,
        isPromoOfferEligibilityLoading: Bool = true
    ) -> Bool {
        let offerEligibility = OfferEligibilityState(
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            loading: .init(
                intro: isIntroOfferEligibilityLoading,
                promo: isPromoOfferEligibilityLoading
            )
        )
        return offerEligibility.visibilityCanChange(
            variesWithEligibility: viewModel.dependsOnOfferEligibility
        ) { intro, promo in
            viewModel.visible(
                state: state,
                condition: condition,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                conditionContext: .init()
            )
        }
    }

    static func makeViewModel(
        visible: Bool? = nil,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>? = nil
    ) -> StackComponentViewModel {
        return StackComponentViewModel(
            component: .init(visible: visible, components: [], overrides: overrides),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make())
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class CompositeOfferEligibilityVisibilityTests: TestCase {

    func testStaticConditionsDoNotRedactWhileEligibilityLoads() throws {
        let viewModels = try Self.makeViewModels(condition: .selected)

        expect(self.redacts(viewModels.carousel)).to(beFalse())
        expect(self.redacts(viewModels.tabs)).to(beFalse())
        expect(self.redacts(viewModels.timeline)).to(beFalse())
        expect(self.redacts(viewModels.timelineItem)).to(beFalse())
    }

    func testIntroOfferVisibilityConditionsRedactWhileEligibilityLoads() throws {
        let viewModels = try Self.makeViewModels(condition: .introOffer)

        expect(self.redacts(viewModels.carousel)).to(beTrue())
        expect(self.redacts(viewModels.tabs)).to(beTrue())
        expect(self.redacts(viewModels.timeline)).to(beTrue())
        expect(self.redacts(viewModels.timelineItem)).to(beTrue())
    }

    func testCompositeComponentsStopRedactingWhenEligibilityResolves() throws {
        let viewModels = try Self.makeViewModels(condition: .introOffer)
        let offerEligibility = OfferEligibilityState(
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false,
            loading: []
        )

        expect(self.redacts(viewModels.carousel, offerEligibility: offerEligibility)).to(beFalse())
        expect(self.redacts(viewModels.tabs, offerEligibility: offerEligibility)).to(beFalse())
        expect(self.redacts(viewModels.timeline, offerEligibility: offerEligibility)).to(beFalse())
        expect(self.redacts(viewModels.timelineItem, offerEligibility: offerEligibility)).to(beFalse())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension CompositeOfferEligibilityVisibilityTests {

    typealias ViewModels = (
        carousel: CarouselComponentViewModel,
        tabs: TabsComponentViewModel,
        timeline: TimelineComponentViewModel,
        timelineItem: TimelineItemViewModel
    )

    var loadingOfferEligibility: OfferEligibilityState {
        return .init(
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            loading: [.intro, .promo]
        )
    }

    func redacts(
        _ viewModel: CarouselComponentViewModel,
        offerEligibility: OfferEligibilityState? = nil
    ) -> Bool {
        return self.redacts(viewModel, offerEligibility: offerEligibility) { intro, promo in
            viewModel.visible(
                state: .default,
                condition: .compact,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                selectedPackageId: nil,
                customVariables: [:]
            )
        }
    }

    func redacts(
        _ viewModel: TabsComponentViewModel,
        offerEligibility: OfferEligibilityState? = nil
    ) -> Bool {
        return self.redacts(viewModel, offerEligibility: offerEligibility) { intro, promo in
            viewModel.visible(
                state: .default,
                condition: .compact,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                selectedPackageId: nil,
                customVariables: [:]
            )
        }
    }

    func redacts(
        _ viewModel: TimelineComponentViewModel,
        offerEligibility: OfferEligibilityState? = nil
    ) -> Bool {
        return self.redacts(viewModel, offerEligibility: offerEligibility) { intro, promo in
            viewModel.visible(
                state: .default,
                condition: .compact,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                selectedPackageId: nil,
                customVariables: [:]
            )
        }
    }

    func redacts(
        _ viewModel: TimelineItemViewModel,
        offerEligibility: OfferEligibilityState? = nil
    ) -> Bool {
        return self.redacts(viewModel, offerEligibility: offerEligibility) { intro, promo in
            viewModel.visible(
                state: .default,
                condition: .compact,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                selectedPackageId: nil,
                customVariables: [:]
            )
        }
    }

    func redacts<Dependency: OfferEligibilityVisibilityDependency>(
        _ dependency: Dependency,
        offerEligibility: OfferEligibilityState?,
        isVisible: (Bool, Bool) -> Bool
    ) -> Bool {
        return (offerEligibility ?? self.loadingOfferEligibility).visibilityCanChange(
            variesWithEligibility: dependency.dependsOnOfferEligibility,
            isVisible: isVisible
        )
    }

    static func makeViewModels(
        condition: PaywallComponent.ExtendedCondition
    ) throws -> ViewModels {
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let localizationProvider = LocalizationProvider(
            locale: Locale(identifier: "en_US"),
            localizedStrings: ["title": .string("Static text")]
        )
        let stackViewModel = StackComponentViewModel(
            component: .init(components: []),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: uiConfigProvider
        )

        let carousel = CarouselComponentViewModel(
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            component: .init(
                pages: [],
                overrides: [
                    .init(extendedConditions: [condition], properties: .init(visible: false))
                ]
            ),
            pageStackViewModels: []
        )

        let tabs = TabsComponentViewModel(
            component: .init(
                control: .init(type: .buttons, stack: .init(components: [])),
                tabs: [],
                overrides: [
                    .init(extendedConditions: [condition], properties: .init(visible: false))
                ]
            ),
            controlStackViewModel: stackViewModel,
            tabViewModels: [],
            uiConfigProvider: uiConfigProvider
        )

        let itemComponent = self.timelineItem(condition: condition)
        let timelineItem = try self.timelineItemViewModel(
            component: itemComponent,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider
        )
        let timeline = TimelineComponentViewModel(
            component: .init(
                iconAlignment: nil,
                itemSpacing: nil,
                textSpacing: nil,
                columnGutter: nil,
                size: .init(width: .fill, height: .fit(nil)),
                padding: .zero,
                margin: .zero,
                items: [itemComponent],
                overrides: [
                    .init(
                        extendedConditions: [condition],
                        properties: .init(
                            visible: false,
                            iconAlignment: nil,
                            itemSpacing: nil,
                            textSpacing: nil,
                            columnGutter: nil,
                            size: nil,
                            padding: nil,
                            margin: nil
                        )
                    )
                ]
            ),
            items: [timelineItem],
            uiConfigProvider: uiConfigProvider
        )

        return (carousel, tabs, timeline, timelineItem)
    }

    static func timelineItem(
        condition: PaywallComponent.ExtendedCondition
    ) -> PaywallComponent.TimelineComponent.Item {
        return .init(
            title: .init(
                text: "title",
                color: .init(light: .hex("#000000"))
            ),
            description: nil,
            icon: .init(
                baseUrl: "https://example.com",
                iconName: "icon",
                formats: .init(svg: "icon.svg", png: "icon.png", heic: "icon.heic", webp: "icon.webp"),
                size: .init(width: .fixed(24), height: .fixed(24)),
                padding: .zero,
                margin: .zero,
                color: .init(light: .hex("#000000")),
                iconBackground: nil
            ),
            connector: .init(
                width: 1,
                color: .init(light: .hex("#000000")),
                margin: .zero
            ),
            overrides: [
                .init(
                    extendedConditions: [condition],
                    properties: .init(visible: false, connector: nil)
                )
            ]
        )
    }

    static func timelineItemViewModel(
        component: PaywallComponent.TimelineComponent.Item,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider
    ) throws -> TimelineItemViewModel {
        return TimelineItemViewModel(
            component: component,
            title: try TextComponentViewModel(
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                component: component.title
            ),
            description: nil,
            icon: IconComponentViewModel(
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                component: component.icon
            ),
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif
