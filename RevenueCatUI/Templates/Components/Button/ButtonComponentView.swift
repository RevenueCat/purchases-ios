//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentView.swift
//
//  Created by Jay Shortway on 02/10/2024.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView: View {

    private let viewModel: ButtonComponentViewModel

    internal init(viewModel: ButtonComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(
            action: { viewModel.onClick() },
            label: { StackComponentView(viewModel: viewModel.stackViewModel) }
        )
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ButtonComponentView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            ButtonComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    component: .init(
                        action: .navigateBack,
                        stack: .init(
                            components: [
                                PaywallComponent.text(
                                    PaywallComponent.TextComponent(
                                        textLid: "buttonText",
                                        color: .init(light: "#000000")
                                    )
                                )
                            ],
                            backgroundColor: nil
                        )
                    ),
                    locale: Locale(identifier: "en_US"),
                    localizedStrings: [
                        "buttonText": PaywallComponentsData.LocalizationData.string("Do something")
                    ],
                    offering: Offering(identifier: "", serverDescription: "", availablePackages: [])
                )
            )
        }
        .previewLayout(.fixed(width: 400, height: 400))
        .previewDisplayName("Default")
    }
}

#endif

#endif
