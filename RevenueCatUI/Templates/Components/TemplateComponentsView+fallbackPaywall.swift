//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FallbackPaywall.swift
//
//  Created by James Borthwick on 2024-09-03.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateComponentsView {

    static func fallbackPaywallViewModels(error: Error? = nil) -> PaywallComponentViewModel {

        let errorDict: [String: String] = ["errorID": "Error creating paywall"]
        let textComponent = PaywallComponent.TextComponent(
            text: DisplayString(value: errorDict),
            textLid: "errorID",
            color: PaywallComponent.ColorInfo(light:"#000000")
        )
        return try! PaywallComponentViewModel.text(TextComponentViewModel(locale: .current, localization: errorDict, component: textComponent))

    }

}
#endif
