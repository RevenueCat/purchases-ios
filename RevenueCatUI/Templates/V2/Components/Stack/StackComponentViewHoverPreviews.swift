//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentViewHoverPreviews.swift
//
//  Created by Josh Holtz on 9/2/26.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

// In its own file so the canvas doesn't have to compile StackComponentView's large preview
// provider to show these. The component is assembled from small explicitly-typed constants
// because the canvas type-checker rejects it as one big nested literal.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct StackComponentViewHover_Previews: PreviewProvider {

    private static let titleHoverOverride = PaywallComponent.ComponentOverride(
        extendedConditions: [.hover],
        properties: PaywallComponent.PartialTextComponent(
            color: PaywallComponent.ColorScheme(light: .hex("#7C3AED"))
        )
    )

    private static let title = PaywallComponent.TextComponent(
        text: "title",
        fontWeight: .bold,
        color: PaywallComponent.ColorScheme(light: .hex("#111827")),
        fontSize: 18,
        horizontalAlignment: .leading,
        overrides: [titleHoverOverride]
    )

    private static let subtitle = PaywallComponent.TextComponent(
        text: "subtitle",
        color: PaywallComponent.ColorScheme(light: .hex("#6B7280")),
        fontSize: 15,
        horizontalAlignment: .leading
    )

    private static let cardHoverOverride = PaywallComponent.ComponentOverride(
        extendedConditions: [.hover],
        properties: PaywallComponent.PartialStackComponent(
            backgroundColor: PaywallComponent.ColorScheme(light: .hex("#F5F3FF")),
            border: PaywallComponent.Border(
                color: PaywallComponent.ColorScheme(light: .hex("#7C3AED")),
                width: 2
            )
        )
    )

    private static let card = PaywallComponent.StackComponent(
        components: [.text(title), .text(subtitle)],
        dimension: .vertical(.leading, .start),
        size: PaywallComponent.Size(width: .fixed(320), height: .fit(nil)),
        spacing: 6,
        backgroundColor: PaywallComponent.ColorScheme(light: .hex("#ffffff")),
        padding: PaywallComponent.Padding(top: 20, bottom: 20, leading: 20, trailing: 20),
        margin: PaywallComponent.Padding(top: 20, bottom: 20, leading: 20, trailing: 20),
        shape: .rectangle(PaywallComponent.CornerRadiuses(
            topLeading: 16,
            topTrailing: 16,
            bottomLeading: 16,
            bottomTrailing: 16
        )),
        border: PaywallComponent.Border(
            color: PaywallComponent.ColorScheme(light: .hex("#E5E7EB")),
            width: 2
        ),
        overrides: [cardHoverOverride]
    )

    private static let localizations: PaywallComponent.LocalizationDictionary = [
        "title": .string("Annual"),
        "subtitle": .string("$49.99/yr · 7 days free")
    ]

    /// A package-style card: hovering it recolors the card's background and border, and the title
    /// recolors too through subtree hover propagation (its own hover override, activated by the card).
    private static var packageCardPreview: some View {
        StackComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! StackComponentViewModel(
                component: card,
                localizationProvider: LocalizationProvider(
                    locale: Locale.current,
                    localizedStrings: localizations
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
    }

    static var previews: some View {
        // Hovered style forced through the environment, always renders the hovered card
        packageCardPreview
            .previewRequiredPaywallsV2Properties(
                componentHoverState: true
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Package Card - Hovered")

        // Run live on a My Mac destination and mouse over the card to trigger .onHover.
        // Touch destinations render the base style.
        packageCardPreview
            .previewRequiredPaywallsV2Properties()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Package Card - Hover (interactive)")
    }

}

#endif

#endif
