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
        Self.paywall
            .previewLayout(.fixed(width: 400, height: 860))
            .previewDisplayName("Workflow: annual discount with plans in closed sheet")

        Self.plansSheet
            .previewLayout(.fixed(width: 400, height: 860))
            .previewDisplayName("Workflow: all plans sheet with relative discounts")
    }

    static var paywall: some View { WorkflowDiscountPreviewView(sheetPresented: false) }
    static var plansSheet: some View { WorkflowDiscountPreviewView(sheetPresented: true) }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct WorkflowDiscountPreviewView: View {

    private let context: WorkflowContext
    private let packageContext: PackageContext
    @State private var sheet: SheetViewModel?

    init(sheetPresented: Bool) {
        let context = WorkflowDiscountPreviewData.context
        self.context = context
        self.packageContext = WorkflowPaywallView.buildPackageInput(
            stepId: "paywall", context: context, preferredPackage: nil, showZeroDecimalPlacePrices: true
        ).packageContext
        // Seed the production overlay for first-frame snapshots using the workflow's package input.
        self._sheet = .init(initialValue: sheetPresented ? WorkflowDiscountPreviewData.sheetViewModel(context) : nil)
    }

    var body: some View {
        WorkflowPaywallView(
            context: self.context,
            purchaseHandler: .default(),
            introEligibilityChecker: .producing(eligibility: .ineligible),
            showZeroDecimalPlacePrices: true,
            displayCloseButton: false,
            promoOfferCache: nil,
            onDismiss: { }
        )
        .bottomSheet(sheet: self.$sheet, safeAreaInsets: .init(), onSheetContentAppear: nil)
        .previewRequiredPaywallsV2Properties(packageContext: self.packageContext)
        .environment(\.paywallLoadingOverride, false)
        .environment(\.locale, Locale(identifier: "en_US"))
        .preferredColorScheme(.dark)
    }

}

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum WorkflowDiscountPreviewData {

    static let accent = "#D7FA52"
    static let background = "#0B1020"
    static let surface = "#171D33"
    static let muted = "#A9B2C9"
    static let localizations: PaywallComponent.LocalizationDictionary = [
        "brand": .string("M O M E N T U M   /   P R O"),
        "headline": .string("Stronger.\nEvery week."),
        "subtitle": .string("A plan that adapts to you.\nProgress that keeps you going."),
        "week": .string("YOUR WEEK, UPGRADED"),
        "sessions": .string("4"),
        "minutes": .string("35"),
        "progress": .string("+12%"),
        "sessions_label": .string("workouts"),
        "minutes_label": .string("min / session"),
        "progress_label": .string("this month"),
        "benefits": .string("✓  Personalized training plans\n✓  Progress insights that matter\n✓  Unlimited workouts"),
        "recommended": .string("YOUR GOALS. ONE MEMBERSHIP."),
        "all_plans": .string("Explore all plans"),
        "sheet_title": .string("Find your rhythm"),
        "sheet_subtitle": .string("The same full access. Your kind of commitment."),
        "$rc_annual": .string("Annual"),
        "$rc_three_month": .string("3 months"),
        "$rc_monthly": .string("Monthly"),
        "per_month": .string("{{ product.price_per_month }}/mo"),
        "price": .string("{{ product.price }}"),
        "discount": .string("{{ product.relative_discount }} OFF"),
        "selection": .string("○"),
        "selected": .string("●"),
        "continue": .string("Continue"),
        "close": .string("×"),
        "terms": .string("Auto-renews. Cancel anytime."),
        "footer": .string("Restore purchases   ·   Terms   ·   Privacy")
    ]

    static var context: WorkflowContext {
        let products: [(PackageType, Decimal, SubscriptionPeriod)] = [
            (.annual, 79.99, .init(value: 1, unit: .year)),
            (.threeMonth, 34.99, .init(value: 3, unit: .month)),
            (.monthly, 14.99, .init(value: 1, unit: .month))
        ]
        let packages = products.map { type, price, period in
            Package(
                identifier: type.identifier, packageType: type,
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
        let screen = WorkflowScreen(
            name: "Plans", templateName: "components",
            assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
            componentsConfig: .init(base: .init(
                stack: Self.hero,
                stickyFooter: .init(stack: .init(
                    components: [
                        Self.text("recommended", size: 11, color: Self.muted, weight: .semibold),
                        Self.package(.annual, isDefault: true),
                        Self.purchaseButton,
                        .button(.init(
                            action: .navigateTo(destination: .sheet(sheet: Self.plansSheet)),
                            stack: .init(components: [
                                Self.text("all_plans", size: 15, weight: .semibold)
                            ], padding: Self.padding(6))
                        )),
                        Self.text("footer", size: 11, color: Self.muted)
                    ],
                    spacing: 20, backgroundColor: Self.color(Self.background),
                    padding: .init(top: 16, bottom: 28, leading: 24, trailing: 24)
                )),
                background: .color(Self.color(Self.background))
            )),
            componentsLocalizations: ["en_US": Self.localizations],
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

    static var hero: PaywallComponent.StackComponent {
        return .init(
            components: [
                Self.text("brand", size: 12, color: Self.accent, weight: .bold),
                Self.text("headline", size: 44, weight: .bold),
                Self.text("subtitle", size: 16, color: Self.muted),
                .stack(.init(
                    components: [
                        Self.text("week", size: 10, color: Self.muted, weight: .semibold),
                        .stack(.init(
                            components: [
                                Self.metric("sessions", label: "sessions_label"),
                                Self.metric("minutes", label: "minutes_label"),
                                Self.metric("progress", label: "progress_label")
                            ], dimension: .horizontal(.center, .spaceBetween), spacing: 16
                        ))
                    ],
                    spacing: 20, backgroundColor: Self.color(Self.surface),
                    padding: Self.padding(22), shape: Self.rounded(22)
                )),
                Self.text("benefits", size: 15, color: "#DCE2EF", alignment: .leading)
            ],
            spacing: 26, padding: .init(top: 42, bottom: 24, leading: 28, trailing: 28)
        )
    }

    static var plansSheet: PaywallComponent.ButtonComponent.Sheet {
        return .init(
            id: "all_plans", name: "All plans",
            stack: .init(
                components: [
                    .stack(.init(
                        components: [], size: .init(width: .fixed(36), height: .fixed(4)),
                        backgroundColor: Self.color("#454D65"), shape: .pill
                    )),
                    .stack(.init(
                        components: [
                            Self.text("sheet_title", size: 25, weight: .bold, alignment: .leading),
                            .button(.init(
                                action: .navigateBack,
                                stack: .init(
                                    components: [Self.text("close", size: 25, color: Self.muted)],
                                    size: .init(width: .fixed(32), height: .fixed(32))
                                )
                            ))
                        ], dimension: .horizontal(.center, .spaceBetween)
                    )),
                    Self.text("sheet_subtitle", size: 14, color: Self.muted, alignment: .leading),
                    Self.package(.annual, isDefault: true),
                    Self.package(.threeMonth),
                    Self.package(.monthly),
                    Self.purchaseButton,
                    Self.text("terms", size: 12, color: Self.muted)
                ],
                spacing: 20, backgroundColor: Self.color(Self.surface),
                padding: .init(top: 12, bottom: 32, leading: 24, trailing: 24),
                shape: .rectangle(.init(topLeading: 28, topTrailing: 28, bottomLeading: 0, bottomTrailing: 0))
            ),
            backgroundBlur: true, size: nil
        )
    }

    static func sheetViewModel(_ context: WorkflowContext) -> SheetViewModel {
        let factory = ViewModelFactory()
        do {
            return try .init(sheet: Self.plansSheet, sheetStackViewModel: factory.toStackViewModel(
                component: Self.plansSheet.stack,
                packageValidator: factory.packageValidator,
                purchaseButtonCollector: nil,
                localizationProvider: .init(locale: Locale(identifier: "en_US"), localizedStrings: Self.localizations),
                uiConfigProvider: .init(uiConfig: context.uiConfig),
                offering: context.initialOffering, colorScheme: .dark
            ))
        } catch {
            fatalError("Invalid plans sheet preview: \(error)")
        }
    }

    private static var purchaseButton: PaywallComponent {
        return .purchaseButton(.init(
            stack: .init(
                components: [Self.text("continue", size: 19, color: Self.background, weight: .bold)],
                backgroundColor: Self.color(Self.accent), padding: Self.padding(18), shape: .pill
            ),
            action: .inAppCheckout, method: nil, name: nil
        ))
    }

    private static func package(_ type: PackageType, isDefault: Bool = false) -> PaywallComponent {
        let badge: PaywallComponent.Badge? = type == .monthly ? nil : .init(
            style: .overlaid, alignment: .topTrailing,
            stack: .init(
                components: [Self.text("discount", size: 11, color: Self.background, weight: .bold)],
                backgroundColor: Self.color(Self.accent),
                padding: .init(top: 4, bottom: 4, leading: 10, trailing: 10),
                margin: .init(top: 0, bottom: 0, leading: 0, trailing: 14), shape: .pill
            )
        )
        return .package(.init(
            packageID: type.identifier, isSelectedByDefault: isDefault, applePromoOfferProductCode: nil,
            stack: .init(
                components: [
                    .text(.init(
                        text: "selection", color: Self.color(Self.muted),
                        size: .init(width: .fixed(24), height: .fit(nil)), fontSize: 24,
                        overrides: [.init(conditions: [.selected], properties: .init(
                            text: "selected", color: Self.color(Self.accent)
                        ))]
                    )),
                    .stack(.init(
                        components: [
                            Self.text(type.identifier, size: 17, weight: .semibold, alignment: .leading),
                            Self.text("per_month", size: 13, color: Self.muted, alignment: .leading)
                        ], dimension: .vertical(.leading, .start), spacing: 6
                    )),
                    .text(.init(
                        text: "price", fontWeight: .bold, color: Self.color("#FFFFFF"),
                        size: .init(width: .fit(nil), height: .fit(nil)), fontSize: 21
                    ))
                ],
                dimension: .horizontal(.center, .start), spacing: 12,
                backgroundColor: Self.color("#1C233B"), padding: Self.padding(18),
                shape: Self.rounded(18), border: .init(color: Self.color("#46506C"), width: 1),
                badge: badge,
                overrides: [.init(conditions: [.selected], properties: .init(
                    backgroundColor: Self.color("#28342C"),
                    border: .init(color: Self.color(Self.accent), width: 2)
                ))]
            )
        ))
    }

    private static func metric(_ value: String, label: String) -> PaywallComponent {
        return .stack(.init(components: [
            Self.text(value, size: 28, color: Self.accent, weight: .bold),
            Self.text(label, size: 11, color: Self.muted)
        ], spacing: 6))
    }

    private static func text(
        _ key: String,
        size: CGFloat,
        color: String = "#FFFFFF",
        weight: PaywallComponent.FontWeight = .regular,
        alignment: PaywallComponent.HorizontalAlignment = .center
    ) -> PaywallComponent {
        return .text(.init(
            text: key, fontWeight: weight, color: Self.color(color), fontSize: size, horizontalAlignment: alignment
        ))
    }

    private static func color(_ hex: String) -> PaywallComponent.ColorScheme {
        return .init(light: .hex(hex))
    }

    private static func padding(_ value: Double) -> PaywallComponent.Padding {
        return .init(top: value, bottom: value, leading: value, trailing: value)
    }

    private static func rounded(_ radius: Double) -> PaywallComponent.Shape {
        return .rectangle(.init(
            topLeading: radius, topTrailing: radius, bottomLeading: radius, bottomTrailing: radius
        ))
    }

}

#endif
