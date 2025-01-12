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
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

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
            Group {
                if style.visible {
                    Text(.init(style.text))
                        .font(style.font)
                        .fontWeight(style.fontWeight)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(style.textAlignment)
                        .foregroundColorScheme(style.color, uiConfigProvider: self.viewModel.uiConfigProvider)
                        .padding(style.padding)
                        .size(style.size,
                              horizontalAlignment: style.horizontalAlignment)
                        .backgroundStyle(style.backgroundStyle, uiConfigProvider: self.viewModel.uiConfigProvider)
                        .padding(style.margin)
                } else {
                    EmptyView()
                }
            }
        }
    }

}

#if DEBUG

// swiftlint:disable type_body_length
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView_Previews: PreviewProvider {

    static var previews: some View {
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
        .previewDisplayName("Default")

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
                        fontSize: .headingXXL
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
                            "primary": .init(ios: .name("Chalkduster"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "primary",
                        color: .init(light: .hex("#000000")),
                        fontSize: .headingXXL
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
                            "primary": .init(ios: .name("Chalkduster"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "This font name is not configured",
                        color: .init(light: .hex("#000000")),
                        fontSize: .headingXXL
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
                            "primary": .init(ios: .name("This Font Does Not Exist"))
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        fontName: "primary",
                        color: .init(light: .hex("#000000")),
                        fontSize: .headingXXL
                    )
                )
            )
        }
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Custom Font")

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
                            "primary": .hex("#ff0000"),
                            "secondary": .hex("#ffcc00")
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .alias("secondary")),
                        backgroundColor: .init(light: .alias("primary")),
                        fontSize: .headingXXL
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
                            "primary": .hex("#ff0000"),
                            "secondary": .hex("#ffcc00")
                        ]
                    )),
                    component: .init(
                        text: "id_1",
                        color: .init(light: .alias("not a thing")),
                        backgroundColor: .init(light: .alias("also not a thing")),
                        fontSize: .headingXXL
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
                    fontSize: .headingXXL
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
                    fontSize: .bodyS,
                    horizontalAlignment: .leading
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Customizations")

        // State - App Specific
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world"),
                        "id_2": .string("Hello, world on iOS app")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: .init(
                        app: .init(
                            text: "id_2"
                        )
                    )
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("State - App Specific")

        // State - Selected
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hello, world"),
                        "id_2": .string("THIS SHOULDN'T SHOW")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: .init(
                        // None of this should be displayed
                        app: .init(
                            text: "id_2",
                            color: .init(light: .hex("#ffcc00"))
                        ),
                        // Selected should override app
                        states: .init(
                            selected: .init(
                                text: "id_1",
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
                                fontSize: .headingXL
                            )
                        )
                    )
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
                    overrides: .init(
                        conditions: .init(
                            medium: .init(
                                text: "id_2"
                            )
                        )
                    )
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
                    overrides: .init(
                        conditions: .init(
                            medium: .init(
                                text: "id_2"
                            )
                        )
                    )
                )
            )
        )
        .previewRequiredEnvironmentProperties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Has medium but not medium")

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
        .previewRequiredEnvironmentProperties(
            packageContext: .init(
                package: PreviewMock.annualPackage,
                variableContext: .init(packages: [PreviewMock.monthlyPackage, PreviewMock.annualPackage])
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Process variable (V2)")

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
        .previewRequiredEnvironmentProperties(
            packageContext: .init(
                package: PreviewMock.annualPackage,
                variableContext: .init(packages: [PreviewMock.monthlyPackage, PreviewMock.annualPackage])
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Process variable (V1)")
    }
}

#endif

#endif
