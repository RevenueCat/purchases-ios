//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StateManagementPreview.swift
//
//  Demonstrates paywall state management end-to-end:
//   - A top-level `state` dictionary declares an initial value.
//   - Two buttons declare `stateUpdates` that mutate the state on tap.
//   - A Text component has overrides keyed on `.state(...)` conditions, so its
//     content changes in real time when the buttons are tapped.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

private enum StateManagementPreview {

    // MARK: - Components

    static let titleText = PaywallComponent.TextComponent(
        text: "id_title",
        fontWeight: .black,
        color: .init(light: .hex("#000000")),
        padding: .zero,
        margin: .init(top: 0, bottom: 16, leading: 0, trailing: 0),
        fontSize: 24,
        horizontalAlignment: .center
    )

    /// Status text — default content shows OFF; an override flips it to ON when state matches.
    static let statusText = PaywallComponent.TextComponent(
        text: "id_status_off",
        fontWeight: .semibold,
        color: .init(light: .hex("#000000")),
        backgroundColor: .init(light: .hex("#F0F0F0")),
        padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16),
        margin: .init(top: 0, bottom: 16, leading: 0, trailing: 0),
        fontSize: 18,
        horizontalAlignment: .center,
        overrides: [
            .init(
                extendedConditions: [
                    .state(operator: .equals, name: "comparisonOpen", value: .bool(true))
                ],
                properties: .init(
                    text: "id_status_on",
                    color: .init(light: .hex("#FFFFFF")),
                    backgroundColor: .init(light: .hex("#0078D4"))
                )
            )
        ]
    )

    /// Button labels are themselves text components.
    static func buttonLabel(textId: String) -> PaywallComponent.TextComponent {
        return .init(
            text: textId,
            fontWeight: .semibold,
            color: .init(light: .hex("#FFFFFF")),
            padding: .init(top: 12, bottom: 12, leading: 24, trailing: 24),
            margin: .zero,
            fontSize: 16,
            horizontalAlignment: .center
        )
    }

    static let turnOnButton = PaywallComponent.ButtonComponent(
        action: .workflowTrigger,
        stack: .init(
            components: [.text(buttonLabel(textId: "id_btn_on"))],
            size: .init(width: .fit, height: .fit),
            backgroundColor: .init(light: .hex("#22AA66")),
            padding: .zero,
            margin: .init(top: 0, bottom: 8, leading: 0, trailing: 0),
            shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12))
        ),
        stateUpdates: [
            .set(key: "comparisonOpen", value: .literal(.bool(true)))
        ]
    )

    static let turnOffButton = PaywallComponent.ButtonComponent(
        action: .workflowTrigger,
        stack: .init(
            components: [.text(buttonLabel(textId: "id_btn_off"))],
            size: .init(width: .fit, height: .fit),
            backgroundColor: .init(light: .hex("#AA2222")),
            padding: .zero,
            margin: .zero,
            shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12))
        ),
        stateUpdates: [
            .set(key: "comparisonOpen", value: .literal(.bool(false)))
        ]
    )

    // MARK: - Carousel section

    /// Builds a single slide stack (one carousel page) with a label text.
    static func slide(textId: String, hex: String) -> PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: textId,
                    fontWeight: .bold,
                    color: .init(light: .hex("#FFFFFF")),
                    padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16),
                    margin: .zero,
                    fontSize: 18,
                    horizontalAlignment: .center
                ))
            ],
            dimension: .vertical(.center, .center),
            size: .init(width: .fill, height: .fixed(80)),
            backgroundColor: .init(light: .hex(hex)),
            shape: .rectangle(.init(topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: 12))
        )
    }

    /// Carousel writes its destination page index into state key "currentSlide" on every page change.
    static let carousel = PaywallComponent.CarouselComponent(
        size: .init(width: .fill, height: .fixed(120)),
        pages: [
            slide(textId: "id_slide_1", hex: "#4287F5"),
            slide(textId: "id_slide_2", hex: "#42B27D"),
            slide(textId: "id_slide_3", hex: "#E0823F")
        ],
        pageAlignment: .center,
        pageSpacing: 8,
        pagePeek: 20,
        initialPageIndex: 0,
        loop: false,
        stateUpdates: [
            .set(key: "currentSlide", value: .payloadReference)
        ]
    )

    /// Text that reads "currentSlide" state and shows the active slide index.
    static let slideIndicatorText = PaywallComponent.TextComponent(
        text: "id_slide_label_0",
        fontWeight: .medium,
        color: .init(light: .hex("#444444")),
        padding: .zero,
        margin: .init(top: 8, bottom: 0, leading: 0, trailing: 0),
        fontSize: 14,
        horizontalAlignment: .center,
        overrides: [
            .init(
                extendedConditions: [.state(operator: .equals, name: "currentSlide", value: .int(1))],
                properties: .init(text: "id_slide_label_1")
            ),
            .init(
                extendedConditions: [.state(operator: .equals, name: "currentSlide", value: .int(2))],
                properties: .init(text: "id_slide_label_2")
            )
        ]
    )

    // MARK: - Tabs section

    static func tabButtonStack(textId: String, hex: String) -> PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: textId,
                    fontWeight: .semibold,
                    color: .init(light: .hex("#FFFFFF")),
                    padding: .init(top: 8, bottom: 8, leading: 16, trailing: 16),
                    margin: .zero,
                    fontSize: 14,
                    horizontalAlignment: .center
                ))
            ],
            size: .init(width: .fit, height: .fit),
            backgroundColor: .init(light: .hex(hex)),
            padding: .zero,
            margin: .zero,
            shape: .rectangle(.init(topLeading: 8, topTrailing: 8, bottomLeading: 8, bottomTrailing: 8))
        )
    }

    static let tabControlA = PaywallComponent.TabControlButtonComponent(
        tabId: "monthly",
        stack: tabButtonStack(textId: "id_tab_monthly", hex: "#666666")
    )

    static let tabControlB = PaywallComponent.TabControlButtonComponent(
        tabId: "yearly",
        stack: tabButtonStack(textId: "id_tab_yearly", hex: "#666666")
    )

    static let tabsControlStack = PaywallComponent.StackComponent(
        components: [
            .tabControlButton(tabControlA),
            .tabControlButton(tabControlB)
        ],
        dimension: .horizontal(.center, .center),
        size: .init(width: .fit, height: .fit),
        spacing: 8,
        padding: .zero,
        margin: .init(top: 0, bottom: 8, leading: 0, trailing: 0)
    )

    static let tabsControl = PaywallComponent.TabsComponent.TabControl(
        type: .buttons,
        stack: tabsControlStack
    )

    /// Each tab's stack includes a `.tabControl(.init())` placeholder. The renderer replaces it
    /// with the actual control widget (the row of tab buttons declared on `TabsComponent.control`),
    /// so the user has something to tap to switch tabs.
    static let tabMonthly = PaywallComponent.TabsComponent.Tab(
        id: "monthly",
        stack: .init(
            components: [
                .tabControl(.init()),
                .text(.init(
                    text: "id_tab_monthly_body",
                    color: .init(light: .hex("#000000")),
                    backgroundColor: .init(light: .hex("#F0F0F0")),
                    padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16),
                    margin: .init(top: 8, bottom: 0, leading: 0, trailing: 0),
                    fontSize: 14,
                    horizontalAlignment: .center
                ))
            ],
            spacing: 0
        )
    )

    static let tabYearly = PaywallComponent.TabsComponent.Tab(
        id: "yearly",
        stack: .init(
            components: [
                .tabControl(.init()),
                .text(.init(
                    text: "id_tab_yearly_body",
                    color: .init(light: .hex("#000000")),
                    backgroundColor: .init(light: .hex("#F0F0F0")),
                    padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16),
                    margin: .init(top: 8, bottom: 0, leading: 0, trailing: 0),
                    fontSize: 14,
                    horizontalAlignment: .center
                ))
            ],
            spacing: 0
        )
    )

    /// Tabs writes the selected tab id into state key "activeTab" on every selection.
    static let tabs = PaywallComponent.TabsComponent(
        size: .init(width: .fill, height: .fit),
        control: tabsControl,
        tabs: [tabMonthly, tabYearly],
        defaultTabId: "monthly",
        stateUpdates: [
            .set(key: "activeTab", value: .payloadReference)
        ]
    )

    /// Text that reads "activeTab" state and shows the active tab id.
    static let tabIndicatorText = PaywallComponent.TextComponent(
        text: "id_tab_label_monthly",
        fontWeight: .medium,
        color: .init(light: .hex("#444444")),
        padding: .zero,
        margin: .init(top: 8, bottom: 0, leading: 0, trailing: 0),
        fontSize: 14,
        horizontalAlignment: .center,
        overrides: [
            .init(
                extendedConditions: [.state(operator: .equals, name: "activeTab", value: .string("yearly"))],
                properties: .init(text: "id_tab_label_yearly")
            )
        ]
    )

    // MARK: - Section dividers / headers

    static func sectionHeader(_ textId: String) -> PaywallComponent.TextComponent {
        return .init(
            text: textId,
            fontWeight: .bold,
            color: .init(light: .hex("#888888")),
            padding: .zero,
            margin: .init(top: 24, bottom: 8, leading: 0, trailing: 0),
            fontSize: 12,
            horizontalAlignment: .leading
        )
    }

    static let rootStack = PaywallComponent.StackComponent(
        components: [
            .text(titleText),

            .text(sectionHeader("id_section_button")),
            .text(statusText),
            .button(turnOnButton),
            .button(turnOffButton),

            .text(sectionHeader("id_section_carousel")),
            .carousel(carousel),
            .text(slideIndicatorText),

            .text(sectionHeader("id_section_tabs")),
            .tabs(tabs),
            .text(tabIndicatorText)
        ],
        dimension: .vertical(.center, .start),
        size: .init(width: .fill, height: .fill),
        spacing: 4,
        padding: .init(top: 40, bottom: 40, leading: 24, trailing: 24)
    )

    // MARK: - Paywall data

    static let paywallComponents: Offering.PaywallComponents = .init(
        uiConfig: .init(
            app: .init(colors: [:], fonts: [:]),
            localizations: [:],
            variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
        ),
        data: data
    )

    static let data: PaywallComponentsData = .init(
        templateName: "components",
        assetBaseURL: URL(string: "https://assets.pawwalls.com")!,
        componentsConfig: .init(
            base: .init(
                stack: rootStack,
                stickyFooter: nil,
                background: .color(.init(light: .hex("#FFFFFF")))
            )
        ),
        componentsLocalizations: ["en_US": [
            "id_title": .string("State Management Demo"),

            "id_section_button":   .string("BUTTONS → BOOL STATE"),
            "id_section_carousel": .string("CAROUSEL → INT STATE"),
            "id_section_tabs":     .string("TABS → STRING STATE"),

            "id_status_off": .string("Comparison is OFF"),
            "id_status_on":  .string("Comparison is ON"),
            "id_btn_on":     .string("Turn ON"),
            "id_btn_off":    .string("Turn OFF"),

            "id_slide_1": .string("Slide 1"),
            "id_slide_2": .string("Slide 2"),
            "id_slide_3": .string("Slide 3"),
            "id_slide_label_0": .string("Active slide: 0"),
            "id_slide_label_1": .string("Active slide: 1"),
            "id_slide_label_2": .string("Active slide: 2"),

            "id_tab_monthly":      .string("Monthly"),
            "id_tab_yearly":       .string("Yearly"),
            "id_tab_monthly_body": .string("Pay $9.99 per month."),
            "id_tab_yearly_body":  .string("Pay $79.99 per year (save 33%)."),
            "id_tab_label_monthly": .string("Active tab: monthly"),
            "id_tab_label_yearly":  .string("Active tab: yearly")
        ]],
        revision: 1,
        defaultLocaleIdentifier: "en_US",
        state: [
            "comparisonOpen": .bool(false),
            "currentSlide":   .int(0),
            "activeTab":      .string("monthly")
        ]
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StateManagementPreview_Previews: PreviewProvider {

    static var previews: some View {
        PaywallsV2View(
            paywallComponents: StateManagementPreview.paywallComponents,
            offering: .init(
                identifier: "default",
                serverDescription: "",
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            purchaseHandler: PurchaseHandler.default(),
            introEligibilityChecker: .default(),
            showZeroDecimalPlacePrices: true,
            onDismiss: { },
            failedToLoadFont: { _ in },
            colorScheme: .light
        )
        .previewDisplayName("State Management Demo")
    }

}

#endif

#endif
