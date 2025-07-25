//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

// swiftlint:disable file_length

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    private let viewModel: TextComponentViewModel

    internal init(viewModel: TextComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            packageContext: self.packageContext,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            )
        ) { style in
            if style.visible {
                NonLocalizedMarkdownText(text: style.text, font: style.font, fontWeight: style.fontWeight)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(style.textAlignment)
                    .foregroundColorScheme(style.color)
                    .padding(style.padding)
                    .size(style.size,
                          horizontalAlignment: style.horizontalAlignment)
                    .backgroundStyle(style.backgroundStyle)
                    .padding(style.margin)
            }
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
/// Parses markdown using AttributedString and does not use bundle assets for localization
private struct NonLocalizedMarkdownText: View {

    let text: String
    let font: Font
    let fontWeight: Font.Weight

    var markdownText: AttributedString? {
        #if swift(>=5.7)
        return try? AttributedString(
            markdown: self.text,
            // We want to only process inline markdown, preserving line feeds in the original text.
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnly)
        )
        #else
        return nil
        #endif
    }

    var body: some View {
        #if swift(>=5.7)
        Group {
            if let markdownText = self.markdownText {
                // Use markdown if we can successfully parse it
                Text(markdownText)
                    .font(self.font)
                    .fontWeight(self.fontWeight)
            } else {
                // Display text as is because markdown is priority
                Text(self.text)
                    .font(self.font)
                    .fontWeight(self.fontWeight)
            }
        }
        #else
        // Display text as is because markdown is priority
        Text(self.text)
            .font(self.font)
            .fontWeight(self.fontWeight)
        #endif
    }
}

#if DEBUG

// Needed for Xcode 14 since there are more than 10 previews
#if swift(>=5.9)

// swiftlint:disable type_body_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView_Previews: PreviewProvider {
    private static var platformPreview: some View {
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string(ProcessInfo.processInfo.platformString)
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)

    }

    private static var defaultPreview: some View {
        // Default
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)

    }

    static var previews: some View {
        defaultPreview
        .previewDisplayName("Default")

        platformPreview
        .previewDisplayName("Detected Platform")

        // Markdown
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        // swiftlint:disable:next line_length
                        "id_1": .string("Hello, world\n**bold**\n_italic_ \n`code`\n[RevenueCat](https://revenuecat.com)")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Markdown")

        // Markdown - Invalid
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world\n**bold\n_italic\n`code \n[RevenueCat](https://revenuecat.com")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Markdown - Invalid")

        // Blank line
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Before blank line.\n\nAfter blank line.")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Blank line")

        // Custom Font
        VStack {
            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )

            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        fonts: [
                            "primary": UIConfig.FontsConfig(ios: UIConfig.FontInfo(name: "Chalkduster"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "primary",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )

            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        fonts: [
                            "primary": UIConfig.FontsConfig(ios: UIConfig.FontInfo(name: "Chalkduster"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "This font name is not configured",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )

            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        fonts: [
                            "primary": UIConfig.FontsConfig(ios: UIConfig.FontInfo(name: "This Font Does Not Exist"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "primary",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Custom Font")

        // Custom Font - Generic
        VStack {
            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        fonts: [
                            "generic": UIConfig.FontsConfig(ios: UIConfig.FontInfo(name: "serif"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "generic",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )

            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        fonts: [
                            "generic": UIConfig.FontsConfig(ios: UIConfig.FontInfo(name: "sans-serif"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "generic",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )

            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Hello, world")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        fonts: [
                            "generic": UIConfig.FontsConfig(ios: UIConfig.FontInfo(name: "monospace"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "generic",
                        color: .init(light: .hex("#000000")),
                        fontSize: 40
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Custom Font - Generic")

        // Custom Color
        VStack {
            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Red bg, yellow fg")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        colors: [
                            "primary": .init(light: .hex("#ff0000")),
                            "secondary": .init(light: .hex("#ffcc00"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .alias("secondary")),
                        backgroundColor: .init(light: .alias("primary")),
                        fontSize: 40
                    )
                )
            )

            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string("Clear bg and default fg")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make(
                        colors: [
                            "primary": .init(light: .hex("#ff0000")),
                            "secondary": .init(light: .hex("#ffcc00"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .alias("not a thing")),
                        backgroundColor: .init(light: .alias("also not a thing")),
                        fontSize: 40
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Custom Color")

        // Gradient
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: PaywallComponent.ColorScheme(
                        light: .linear(30, [
                            .init(color: "#0433FF", percent: 0),
                            .init(color: "#FF40FF", percent: 50),
                            .init(color: "#00FDFF", percent: 100)
                        ]),
                        dark: .linear(30, [
                            .init(color: "#0433FF", percent: 0),
                            .init(color: "#FF40FF", percent: 50),
                            .init(color: "#00FDFF", percent: 100)
                        ])
                      ),
                    fontSize: 40
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Gradient")

        // Customizations
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    fontName: nil,
                    fontWeight: .black,
                    color: .init(light: .hex("#ff0000")),
                    backgroundColor: .init(light: .hex("#dedede")),
                    padding: .init(top: 10,
                                   bottom: 10,
                                   leading: 20,
                                   trailing: 20),
                    margin: .init(top: 20,
                                  bottom: 20,
                                  leading: 10,
                                  trailing: 10),
                    fontSize: 13,
                    horizontalAlignment: .leading
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Customizations")

        // State - Selected
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(conditions: [
                            .selected
                        ], properties: .init(
                            fontWeight: .black,
                            color: .init(light: .hex("#ff0000")),
                            backgroundColor: .init(light: .hex("#0000ff")),
                            padding: .init(top: 10,
                                           bottom: 10,
                                           leading: 10,
                                           trailing: 10),
                            margin: .init(top: 10,
                                          bottom: 10,
                                          leading: 10,
                                          trailing: 10),
                            fontSize: 34
                        ))
                    ]
                )
            )
        )
        .previewRequiredEnvironmentProperties(
            componentViewState: .selected
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("State - Selected")

        // Condition - Medium
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("THIS TEXT SHOULDN'T SHOW"),
                        "id_2": .string("Showing medium condition")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(conditions: [
                            .medium
                        ], properties: .init(
                            text: "id_2"
                        ))
                    ]
                )
            )
        )
        .previewRequiredEnvironmentProperties(
            screenCondition: .medium
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Medium")

        // Condition - Has medium but not medium
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Showing compact condition"),
                        "id_2": .string("SHOULDN'T SHOW MEDIUM")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(conditions: [
                            .medium
                        ], properties: .init(
                            text: "id_2"
                        ))
                    ]
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Has medium but not medium")

        VStack {
            // Process variable (V2)
            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string(
                                "{{ product.store_product_name }} is " +
                                "{{ product.price_per_period }} " +
                                "({{ product.relative_discount }})"
                            )
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .hex("#000000"))
                    )
                )
            )

            // Process variable (V1)
            TextComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_1": .string(
                                "{{ product_name }} is " +
                                "{{ price_per_period_full }} " +
                                "({{ sub_relative_discount }})"
                            )
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .hex("#000000"))
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties(
            packageContext: .init(
                package: PreviewMock.annualStandardPackage,
                variableContext: .init(packages: [
                    PreviewMock.monthlyStandardPackage,
                    PreviewMock.annualStandardPackage
                ])
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Process variable")

    }
}

#endif

#endif

#endif
