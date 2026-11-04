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

/// Minimal layouts reproducing PW10's tab memory and PW11's competing defaults.
@available(iOS 15.0, *)
@MainActor
struct PackageResolutionTestFixture {

    let state: PaywallState
    let tabs: TabsComponentViewModel
    let offering: Offering
    let context: PackageContext

    init(competingDefaults: Bool = false) throws {
        var monthlyXL = TestData.monthlyProduct
        monthlyXL.price = 29.99
        monthlyXL.localizedPriceString = "$29.99"
        monthlyXL.productIdentifier += ".xl"
        var annualXL = TestData.annualProduct
        annualXL.price = 199.99
        annualXL.localizedPriceString = "$199.99"
        annualXL.productIdentifier += ".xl"
        let packages = [
            TestData.monthlyPackage,
            TestData.annualPackage,
            Package(identifier: "monthly_xl", packageType: .custom, storeProduct: monthlyXL.toStoreProduct(),
                    offeringIdentifier: "test", webCheckoutUrl: nil),
            Package(identifier: "annual_xl", packageType: .custom, storeProduct: annualXL.toStoreProduct(),
                    offeringIdentifier: "test", webCheckoutUrl: nil)
        ]
        self.offering = Offering(identifier: "test", serverDescription: "", availablePackages: packages,
                                 webCheckoutUrl: nil)
        let standard = competingDefaults
            ? [Self.package("$rc_annual", selected: true)]
            : [Self.package("$rc_monthly", selected: true), Self.package("$rc_annual", selected: false)]
        let xlComponents = competingDefaults
            ? [Self.package("monthly_xl", selected: true)]
            : [Self.package("monthly_xl", selected: true), Self.package("annual_xl", selected: false)]
        var components: [PaywallComponent] = competingDefaults ? [Self.package("$rc_monthly", selected: true)] : []
        components.append(.tabs(.init(
            control: .init(type: .buttons, stack: .init(components: [])),
            tabs: [.init(id: "tab-1", stack: .init(components: standard)),
                   .init(id: "tab-2", stack: .init(components: xlComponents))],
            defaultTabId: "tab-1"
        )))
        if competingDefaults {
            let sheet = PaywallComponent.ButtonComponent.Sheet(
                id: "competing-sheet", name: "Sheet default",
                stack: .init(components: [
                    Self.package("annual_xl", selected: true),
                    .purchaseButton(.init(
                        stack: .init(components: [Self.text("Purchase from sheet")]),
                        action: .inAppCheckout, method: .inAppCheckout, name: nil
                    ))
                ]),
                backgroundBlur: false, size: .init(width: .fill, height: .fit(nil))
            )
            components.append(.button(.init(action: .navigateTo(destination: .sheet(sheet: sheet)),
                                            stack: .init(components: [Self.text("Open sheet")]))))
        }
        self.state = try PaywallsV2View.createPaywallState(
            componentsConfig: .init(stack: .init(components: components), stickyFooter: nil,
                                    background: .color(.init(light: .hex("#FFFFFF")))),
            componentsLocalizations: ["en_US": [
                "Package": .string("Package"), "Open sheet": .string("Open sheet"),
                "Purchase from sheet": .string("Purchase from sheet")
            ]],
            preferredLocales: [Locale(identifier: "en_US")],
            defaultLocale: "en_US",
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            offering: self.offering,
            introEligibilityChecker: BaseSnapshotTest.eligibleChecker,
            showZeroDecimalPlacePrices: false,
            colorScheme: .light
        ).get()
        self.tabs = try XCTUnwrap(self.state.rootViewModel.stackViewModel.viewModels.compactMap {
            if case .tabs(let tabs) = $0 { return tabs }
            return nil
        }.first)
        self.context = PackageContext(
            package: self.state.viewModelFactory.packageValidator.defaultSelectedPackage(in: .provisional),
            variableContext: .init(packages: packages, showZeroDecimalPlacePrices: false)
        )
    }

    func view() -> some View {
        let intro = IntroOfferEligibilityContext(introEligibilityChecker: BaseSnapshotTest.eligibleChecker)
        return LoadedPaywallsV2View(
            introOfferEligibilityContext: intro,
            paywallState: self.state,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            selectedPackageContext: self.context,
            workflowDefaultPackage: nil,
            onDismiss: {}
        )
        .environmentObject(PurchaseHandler.mock())
        .environmentObject(intro)
        .environmentObject(PaywallPromoOfferCache(subscriptionHistoryTracker: SubscriptionHistoryTracker()))
        .environment(\.screenCondition, .compact)
    }

    func select(_ identifier: String, tab: String) throws {
        let context = try XCTUnwrap(self.context.tabsState(for: self.tabs).contextsByTabId[tab])
        context.update(package: try XCTUnwrap(self.offering.package(identifier: identifier)),
                       variableContext: context.variableContext)
        Self.settle()
    }

    /// Async hosted tests must yield the main actor so sheet layout/animation dispatches can run.
    static func settlePresentation() async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
    }

    static func settle() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
    }

}

@available(iOS 15.0, *)
private extension PackageResolutionTestFixture {

    static func package(_ identifier: String, selected: Bool) -> PaywallComponent {
        .package(.init(packageID: identifier, isSelectedByDefault: selected, applePromoOfferProductCode: nil,
                       stack: .init(components: [Self.text("Package")])))
    }

    static func text(_ value: String) -> PaywallComponent {
        .text(.init(text: value, color: .init(light: .hex("#000000"))))
    }

}

#endif
