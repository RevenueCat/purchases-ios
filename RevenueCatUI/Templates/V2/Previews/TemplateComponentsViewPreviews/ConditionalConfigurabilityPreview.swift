//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConditionalConfigurabilityPreview.swift
//
//  Created by RevenueCat on 3/4/26.

// swiftlint:disable file_length type_body_length force_try

#if !os(tvOS) // For Paywalls V2

#if DEBUG

#if swift(>=5.9)

@_spi(Internal) import RevenueCat
import SwiftUI

// MARK: - Text visibility with variable conditions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ConditionalVisibility_Previews: PreviewProvider {

    static var previews: some View {

        // MARK: Variable condition hides text (condition matches)
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("This text should be hidden")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "hide_text", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["hide_text": .bool(true)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: hide_text=true (equals) → text hidden")

        // MARK: Variable condition does NOT hide text (condition doesn't match)
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("This text should be visible")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "hide_text", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["hide_text": .bool(false)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: hide_text=false (equals) → text visible")

        // MARK: Variable condition with notEquals operator
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Shown via notEquals")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .notEquals, variable: "tier", value: .string("free"))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: tier='premium' notEquals 'free' matches → text hidden")

        // MARK: Variable condition changes text content
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_base": .string("Free tier"),
                        "id_premium": .string("Welcome back, Premium!")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_base",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium"))
                            ],
                            properties: .init(
                                text: "id_premium",
                                color: .init(light: .hex("#FFD700"))
                            )
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: tier='premium' (equals) → shows gold 'Welcome back, Premium!'")

        // MARK: Variable condition does NOT change text (no match)
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_base": .string("Free tier"),
                        "id_premium": .string("Welcome back, Premium!")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_base",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium"))
                            ],
                            properties: .init(
                                text: "id_premium",
                                color: .init(light: .hex("#FFD700"))
                            )
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("free")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: tier='free' (equals 'premium') → shows base 'Free tier'")

        // MARK: Missing variable — equals condition does not match
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Visible because variable is missing")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "missing_var", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, [:])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: missing variable (equals) → no match → text visible")

        // MARK: Missing variable — notEquals condition DOES match
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Hidden because missing var notEquals anything")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .notEquals, variable: "missing_var", value: .string("any"))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, [:])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: missing variable (notEquals) → matches → text hidden")

        // MARK: Multiple conditions (AND) — both match → override applies
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("Both conditions met → hidden")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium")),
                                .variable(operator: .equals, variable: "hide_ads", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium"), "hide_ads": .bool(true)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: tier=premium AND hide_ads=true both match → text hidden")

        // MARK: Multiple conditions (AND) — one fails → override does NOT apply
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_1": .string("One condition fails → visible")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium")),
                                .variable(operator: .equals, variable: "hide_ads", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                )
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium"), "hide_ads": .bool(false)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Text: tier=premium matches but hide_ads=false fails → text visible")
    }

}

// MARK: - Stack visibility with variable conditions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ConditionalStackVisibility_Previews: PreviewProvider {

    static var previews: some View {

        // MARK: Stack hidden by variable condition (hides children too)
        StackComponentView(
            viewModel: try! .init(
                component: .init(
                    components: [
                        .text(.init(
                            text: "text_1",
                            color: .init(light: .hex("#000000"))
                        ))
                    ],
                    size: .init(width: .fill, height: .fit),
                    backgroundColor: .init(light: .hex("#ff0000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "hide_banner", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "text_1": .string("This banner should be hidden")
                    ]
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["hide_banner": .bool(true)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Stack: hide_banner=true (equals) → red banner and text hidden")

        // MARK: Stack visible when variable condition doesn't match
        StackComponentView(
            viewModel: try! .init(
                component: .init(
                    components: [
                        .text(.init(
                            text: "text_1",
                            color: .init(light: .hex("#ffffff"))
                        ))
                    ],
                    size: .init(width: .fill, height: .fit),
                    backgroundColor: .init(light: .hex("#007AFF")),
                    padding: .init(top: 12, bottom: 12, leading: 16, trailing: 16),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "hide_banner", value: .bool(true))
                            ],
                            properties: .init(visible: false)
                        )
                    ]
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "text_1": .string("This banner is visible")
                    ]
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["hide_banner": .bool(false)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Stack: hide_banner=false (equals) → blue banner and text visible")

        // MARK: Mixed visibility — one child hidden, one visible
        StackComponentView(
            viewModel: try! .init(
                component: .init(
                    components: [
                        .text(.init(
                            text: "id_always",
                            color: .init(light: .hex("#000000"))
                        )),
                        .text(.init(
                            text: "id_conditional",
                            color: .init(light: .hex("#ff0000")),
                            overrides: [
                                .init(
                                    extendedConditions: [
                                        .variable(operator: .equals, variable: "show_promo", value: .bool(false))
                                    ],
                                    properties: .init(visible: false)
                                )
                            ]
                        ))
                    ],
                    size: .init(width: .fill, height: .fit)
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_always": .string("Always visible text"),
                        "id_conditional": .string("Conditionally hidden text")
                    ]
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["show_promo": .bool(false)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Stack: show_promo=false → promo text hidden, 'Always visible' shown")

        // MARK: Mixed visibility — both visible
        StackComponentView(
            viewModel: try! .init(
                component: .init(
                    components: [
                        .text(.init(
                            text: "id_always",
                            color: .init(light: .hex("#000000"))
                        )),
                        .text(.init(
                            text: "id_conditional",
                            color: .init(light: .hex("#00AA00")),
                            overrides: [
                                .init(
                                    extendedConditions: [
                                        .variable(operator: .equals, variable: "show_promo", value: .bool(false))
                                    ],
                                    properties: .init(visible: false)
                                )
                            ]
                        ))
                    ],
                    size: .init(width: .fill, height: .fit)
                ),
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_always": .string("Always visible text"),
                        "id_conditional": .string("Conditionally shown text")
                    ]
                ),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["show_promo": .bool(true)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Stack: show_promo=true → both 'Always visible' and promo text shown")
    }

}

// MARK: - Default Paywall behavior (global discardRules)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallBehavior_Previews: PreviewProvider {

    static var previews: some View {

        // MARK: Normal: rule override APPLIES (discardRules=false)
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_base": .string("Base text (free tier)"),
                        "id_premium": .string("Premium override applied!")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_base",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium"))
                            ],
                            properties: .init(
                                text: "id_premium",
                                color: .init(light: .hex("#FFD700"))
                            )
                        )
                    ]
                ),
                discardRules: false
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Normal: rule applies → shows gold 'Premium override applied!'")

        // MARK: Default paywall: rule override DISCARDED (discardRules=true, simulates unsupported elsewhere)
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_base": .string("Base text (free tier)"),
                        "id_premium": .string("Premium override applied!")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_base",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium"))
                            ],
                            properties: .init(
                                text: "id_premium",
                                color: .init(light: .hex("#FFD700"))
                            )
                        )
                    ]
                ),
                discardRules: true
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default paywall: rule discarded → shows black 'Base text (free tier)'")

        // MARK: Default paywall keeps legacy overrides (compact condition still applies)
        TextComponentView(
            viewModel: try! .init(
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "id_base": .string("Default text"),
                        "id_compact": .string("Compact layout text")
                    ]
                ),
                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                component: .init(
                    text: "id_base",
                    color: .init(light: .hex("#000000")),
                    overrides: [
                        .init(
                            extendedConditions: [.compact],
                            properties: .init(
                                text: "id_compact",
                                color: .init(light: .hex("#007AFF"))
                            )
                        ),
                        .init(
                            extendedConditions: [
                                .variable(operator: .equals, variable: "tier", value: .string("premium"))
                            ],
                            properties: .init(
                                fontWeight: .bold
                            )
                        )
                    ]
                ),
                discardRules: true
            )
        )
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["tier": .string("premium")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default paywall: compact override shows blue text, variable rule discarded (not bold)")
    }

}

#endif

#endif

#endif
