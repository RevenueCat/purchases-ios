//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ContainerOfferEligibilityVisibilityTests.swift
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(macOS)
import AppKit
#endif

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ContainerOfferEligibilityVisibilityTests: TestCase {

    func testParentIntroVisibilityChangesWhileEligibilityLoads() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [.introOffer]) {
            XCTAssertTrue(Self.loading().visibilityCanChange(isVisible: isVisible))
        }
    }

    func testParentPromoVisibilityChangesWhileEligibilityLoads() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [
            .promoOfferCondition(operator: .equals, value: false)
        ]) {
            XCTAssertTrue(Self.loading().visibilityCanChange(isVisible: isVisible))
        }
    }

    func testParentIntroVisibilityDoesNotWaitForPromoEligibility() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [.introOffer]) {
            XCTAssertFalse(Self.loading(intro: false).visibilityCanChange(isVisible: isVisible))
        }
    }

    func testParentPromoVisibilityDoesNotWaitForIntroEligibility() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [.promoOffer]) {
            XCTAssertFalse(Self.loading(promo: false).visibilityCanChange(isVisible: isVisible))
        }
    }

    func testParentVisibilityIgnoresUnrelatedScreenConditions() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [.expanded, .introOffer]) {
            XCTAssertFalse(Self.loading().visibilityCanChange(isVisible: isVisible))
        }
    }

    func testInitiallyHiddenParentsCanBecomeVisible() throws {
        for isVisible in try Self.makeVisibilityChecks(
            conditions: [.introOffer],
            visible: false,
            overrideVisibility: true
        ) {
            XCTAssertTrue(Self.loading().visibilityCanChange(isVisible: isVisible))
        }
    }

    func testResolvedEligibilityDoesNotRedactParents() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [.introOffer]) {
            XCTAssertFalse(Self.loading(intro: false, promo: false).visibilityCanChange(isVisible: isVisible))
        }
    }

    func testParentsWithUnchangedVisibilityDoNotRedact() throws {
        for isVisible in try Self.makeVisibilityChecks(conditions: [.introOffer], overrideVisibility: true) {
            XCTAssertFalse(Self.loading().visibilityCanChange(isVisible: isVisible))
        }
    }

    #if os(macOS)
    @MainActor
    func testRedactionEndsWithoutRecreatingChildren() {
        self.assertRedactionTransition(inheritedReasons: [], expectedReasons: [])
    }

    @MainActor
    func testInheritedRedactionRemainsAfterEligibilityResolves() {
        self.assertRedactionTransition(inheritedReasons: .placeholder, expectedReasons: .placeholder)
    }

    @MainActor
    private func assertRedactionTransition(inheritedReasons: RedactionReasons, expectedReasons: RedactionReasons) {
        _ = NSApplication.shared
        let loading = EligibilityLoadingState()
        var reasons: [RedactionReasons] = []
        var appearCount = 0
        let view = NSHostingView(rootView: EligibilityRedactionProbe(
            loading: loading,
            inheritedReasons: inheritedReasons,
            onAppear: { appearCount += 1 },
            onChange: { reasons.append($0) }
        ))
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(reasons.last, .placeholder)

        loading.isLoading = false
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(reasons.last, expectedReasons)
        XCTAssertEqual(appearCount, 1)
    }
    #endif

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ContainerOfferEligibilityVisibilityTests {

    static func loading(intro: Bool = true, promo: Bool = true) -> OfferEligibilityState {
        return .init(
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            isIntroOfferEligibilityLoading: intro,
            isPromoOfferEligibilityLoading: promo
        )
    }

    static func makeVisibilityChecks(
        conditions: [PaywallComponent.ExtendedCondition],
        visible: Bool? = nil,
        overrideVisibility: Bool = false
    ) throws -> [(Bool, Bool) -> Bool] {
        let package = TestData.monthlyPackage
        let offering = Offering(
            identifier: "default", serverDescription: "", availablePackages: [package], webCheckoutUrl: nil
        )
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let stack = PaywallComponent.StackComponent(components: [
            .text(.init(text: "label", color: .init(light: .hex("#000000"))))
        ])
        let localizationProvider = LocalizationProvider(
            locale: Locale(identifier: "en_US"), localizedStrings: ["label": .string("Subscribe")]
        )
        let stackViewModel = try ViewModelFactory().toStackViewModel(
            component: stack,
            packageValidator: PackageValidator(),
            purchaseButtonCollector: nil,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering,
            colorScheme: .light
        )
        let button = try ButtonComponentViewModel(
            component: .init(
                visible: visible,
                action: .navigateBack,
                stack: stack,
                overrides: [.init(extendedConditions: conditions, properties: .init(visible: overrideVisibility))]
            ),
            localizationProvider: localizationProvider,
            offering: offering,
            stackViewModel: stackViewModel,
            uiConfigProvider: uiConfigProvider
        )
        let packageVisibility = PackageVisibilityResolver(
            component: .init(
                packageID: package.identifier,
                isSelectedByDefault: false,
                visible: visible,
                applePromoOfferProductCode: nil,
                stack: stack,
                overrides: [.init(extendedConditions: conditions, properties: .init(visible: overrideVisibility))]
            ),
            uiConfigProvider: uiConfigProvider,
            discardRules: false
        )
        return [
            { intro, promo in
                button.visible(
                    state: .default, condition: .compact,
                    isEligibleForIntroOffer: intro, isEligibleForPromoOffer: promo,
                    selectedPackageId: nil, customVariables: [:]
                )
            },
            { intro, promo in
                packageVisibility.visible(
                    state: .default, condition: .compact,
                    isEligibleForIntroOffer: intro, isEligibleForPromoOffer: promo,
                    selectedPackageId: nil, customVariables: [:]
                )
            }
        ]
    }

}

#if os(macOS)
private class EligibilityLoadingState: ObservableObject {
    @Published var isLoading = true
}

@available(macOS 12.0, *)
private struct EligibilityRedactionProbe: View {
    @ObservedObject var loading: EligibilityLoadingState
    let inheritedReasons: RedactionReasons
    let onAppear: () -> Void
    let onChange: (RedactionReasons) -> Void

    var body: some View {
        RedactionProbe(onAppear: self.onAppear, onChange: self.onChange)
            .redactedWhileOfferEligibilityLoads(
                isEligibleForIntroOffer: false,
                isEligibleForPromoOffer: false,
                isVisible: { intro, _ in !intro }
            )
            .environment(\.isIntroOfferEligibilityLoading, self.loading.isLoading)
            .redacted(reason: self.inheritedReasons)
    }
}

@available(macOS 12.0, *)
private struct RedactionProbe: View {
    @Environment(\.redactionReasons) private var redactionReasons
    let onAppear: () -> Void
    let onChange: (RedactionReasons) -> Void

    var body: some View {
        Text("Subscribe")
            .onAppear {
                self.onAppear()
                self.onChange(self.redactionReasons)
            }
            .onChangeOf(self.redactionReasons, perform: self.onChange)
    }
}
#endif

#endif
