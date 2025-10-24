//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FallbackComponentPreview.swift
//
//  Created by Josh Holtz on 12/29/24.

import RevenueCat
import SwiftUI

// swiftlint:disable force_try

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct FallbackComponentPreview_Previews: PreviewProvider {

    static let jsonStringDefaultStack = """
    {
        "type": "stack",
        "dimension": {
            "type": "vertical",
            "alignment": "center",
            "distribution": "center"
        },
        "size": {
            "width": { "type": "fixed", "value": 200 },
            "height": { "type": "fixed", "value": 100 }
        },
        "padding": {
            "top": 0,
            "bottom": 0,
            "leading": 0,
            "trailing": 0
        },
        "margin": {
            "top": 0,
            "bottom": 0,
            "leading": 0,
            "trailing": 0
        },
        "background_color": {
            "light": {
                "type": "hex",
                "value": "#ffcc00"
            }
        },
        "components": [
            {
                "type": "text",
                "text_lid": "text1",
                "font_weight": "regular",
                "color": {
                    "light": {
                        "type": "hex",
                        "value": "#000000"
                    }
                },
                "font_size": "body_m",
                "horizontal_alignment": "center",
                "padding": {
                    "top": 0,
                    "bottom": 0,
                    "leading": 0,
                    "trailing": 0
                },
                "margin": {
                    "top": 0,
                    "bottom": 0,
                    "leading": 0,
                    "trailing": 0
                },
                "size": {
                    "width": { "type": "fit" },
                    "height": { "type": "fit" }
                }
            }
        ]
    }
    """

    static let jsonStringComponentWithFallback = """
        {
            "type": "super_new_type",
            "unknown_property": {
                "type": "more_unknown"
            },
            "fallback": \(jsonStringDefaultStack)
        }
    """

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return decoder
    }()

    static let componentWithFallback = {
        let jsonData = jsonStringComponentWithFallback.data(using: .utf8)!
        return try! decoder.decode(PaywallComponent.self, from: jsonData)
    }()

    static func toViewModels(
        component: PaywallComponent,
        packageValidator: PackageValidator,
        offering: Offering,
        localizationProvider: LocalizationProvider,
        colorScheme: ColorScheme
    ) -> PaywallComponentViewModel {
        let factory = ViewModelFactory()
        return try! factory.toViewModel(
            component: component,
            packageValidator: packageValidator,
            firstItemIgnoresSafeAreaInfo: nil,
            offering: offering,
            localizationProvider: localizationProvider,
            uiConfigProvider: .init(uiConfig: PreviewUIConfig.make()),
            colorScheme: colorScheme
        )
    }

    static let localizationProvider = LocalizationProvider(
        locale: .init(identifier: "en_US"),
        localizedStrings: [
            "text1": .string("Fallback is showing")
        ]
    )

    static let offering = Offering(identifier: "default",
                                   serverDescription: "",
                                   availablePackages: [],
                                   webCheckoutUrl: nil)

    static var previews: some View {

        // Component With Fallback
        ComponentsView(
            componentViewModels: [
                toViewModels(
                    component: componentWithFallback,
                    packageValidator: PackageValidator(),
                    offering: offering,
                    localizationProvider: localizationProvider,
                    colorScheme: .light
                )
            ],
            onDismiss: {}
        )
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Component With Fallback")
    }
}

#endif

#endif
