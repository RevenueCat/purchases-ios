//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowSheetRelativeDiscountPreview.swift

#if DEBUG && !os(tvOS)

@_spi(Internal) import RevenueCat
import SwiftUI

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowSheetRelativeDiscountPreview: PreviewProvider {

    static var previews: some View {
        WorkflowPaywallView(
            context: Self.context,
            purchaseHandler: .default(),
            introEligibilityChecker: .producing(eligibility: .ineligible),
            showZeroDecimalPlacePrices: true,
            displayCloseButton: false,
            promoOfferCache: nil,
            onDismiss: { }
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.paywallLoadingOverride, false)
        .environment(\.locale, Locale(identifier: "en_US"))
        .previewLayout(.fixed(width: 400, height: 800))
        .previewDisplayName("Workflow: 56% off with other plans in sheet")
    }

    private static var context: WorkflowContext {
        let products: [(PackageType, Decimal, SubscriptionPeriod)] = [
            (.annual, 79.99, .init(value: 1, unit: .year)),
            (.threeMonth, 34.99, .init(value: 3, unit: .month)),
            (.monthly, 14.99, .init(value: 1, unit: .month))
        ]
        let packages = products.map { type, price, period in
            Package(
                identifier: type.identifier,
                packageType: type,
                storeProduct: TestStoreProduct(
                    localizedTitle: type.identifier, price: price, currencyCode: "USD",
                    localizedPriceString: "$\(price)", productIdentifier: type.identifier,
                    productType: .autoRenewableSubscription, localizedDescription: "",
                    subscriptionPeriod: period, locale: Locale(identifier: "en_US")
                ).toStoreProduct(),
                offeringIdentifier: "sheet_discount", webCheckoutUrl: nil
            )
        }
        let offering = Offering(
            identifier: "sheet_discount", serverDescription: "", availablePackages: packages, webCheckoutUrl: nil
        )
        let sheetButton = PaywallComponent.button(.init(
            action: .navigateTo(destination: .sheet(sheet: .init(
                id: "all_plans", name: nil,
                stack: .init(components: products.map { Self.package($0.0) }, spacing: 16),
                backgroundBlur: false, size: nil
            ))),
            stack: .init(
                components: [Self.text("all_plans")],
                padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16)
            )
        ))
        let screen = WorkflowScreen(
            name: "Plans", templateName: "components",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: .init(
                    components: [Self.text("headline")],
                    padding: .init(top: 24, bottom: 24, leading: 24, trailing: 24)
                ),
                stickyFooter: .init(stack: .init(
                    components: [Self.package(.annual, isDefault: true), sheetButton],
                    spacing: 16, padding: .init(top: 24, bottom: 24, leading: 24, trailing: 24)
                )),
                background: .color(.init(light: .hex("#FFFFFF")))
            )),
            componentsLocalizations: ["en_US": [
                "headline": .string("Choose your plan"),
                "all_plans": .string("VIEW ALL PLANS"),
                "$rc_annual": .string("Annual — {{ product.price }}"),
                "$rc_three_month": .string("Quarterly — {{ product.price }}"),
                "$rc_monthly": .string("Monthly — {{ product.price }}"),
                "discount": .string("{{ product.relative_discount }} OFF")
            ]],
            defaultLocale: "en_US", offeringIdentifier: offering.identifier
        )
        let workflow = PublishedWorkflow(
            id: "sheet_discount", displayName: "Sheet discount", initialStepId: "paywall",
            singleStepFallbackId: "paywall",
            steps: ["paywall": .init(id: "paywall", type: "screen", screenId: "plans")],
            screens: ["plans": screen]
        )
        do {
            return try WorkflowPreview.makeContext(
                workflow: workflow, offerings: [offering], uiConfig: PreviewUIConfig.make()
            )
        } catch {
            fatalError("Invalid workflow discount preview: \(error)")
        }
    }

    private static func package(_ type: PackageType, isDefault: Bool = false) -> PaywallComponent {
        return .package(.init(
            packageID: type.identifier, isSelectedByDefault: isDefault, applePromoOfferProductCode: nil,
            stack: .init(
                components: [Self.text(type.identifier), Self.text("discount")],
                spacing: 8, backgroundColor: .init(light: .hex("#F0F0FF")),
                padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16)
            )
        ))
    }

    private static func text(_ key: String) -> PaywallComponent {
        return .text(.init(text: key, fontWeight: .bold, color: .init(light: .hex("#111111"))))
    }

}

#endif
