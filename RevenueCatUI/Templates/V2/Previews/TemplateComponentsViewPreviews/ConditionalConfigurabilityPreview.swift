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
        .previewDisplayName("Variable - Hidden (bool = true)")

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
        .previewDisplayName("Variable - Visible (bool = false)")

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
        .environment(\.customPaywallVariables, ["tier": .string("free")])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Variable - Visible (notEquals matches, so hidden)")

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
        .previewDisplayName("Variable - Text override (premium)")

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
        .previewDisplayName("Variable - Text no override (free)")
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
        .previewDisplayName("Stack - Hidden by variable")

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
        .previewDisplayName("Stack - Visible by variable")

        // MARK: Mixed visibility — one child hidden, one visible
        VStack(spacing: 0) {
            TextComponentView(
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_always": .string("Always visible text")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        text: "id_always",
                        color: .init(light: .hex("#000000"))
                    )
                )
            )

            TextComponentView(
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_conditional": .string("Conditionally hidden text")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
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
                    )
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["show_promo": .bool(false)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Mixed - One hidden, one visible")

        // MARK: Mixed visibility — both visible
        VStack(spacing: 0) {
            TextComponentView(
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_always": .string("Always visible text")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
                        text: "id_always",
                        color: .init(light: .hex("#000000"))
                    )
                )
            )

            TextComponentView(
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [
                            "id_conditional": .string("Conditionally shown text")
                        ]
                    ),
                    uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
                    component: .init(
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
                    )
                )
            )
        }
        .previewRequiredPaywallsV2Properties()
        .environment(\.customPaywallVariables, ["show_promo": .bool(true)])
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Mixed - Both visible")
    }

}

#endif

#endif

#endif
