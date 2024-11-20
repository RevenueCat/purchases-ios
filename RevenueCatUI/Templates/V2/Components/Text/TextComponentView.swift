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
                    Text(style.text)
                        .font(style.fontSize)
                        .fontWeight(style.fontWeight)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(style.textAlignment)
                        .foregroundStyle(style.color)
                        .padding(style.padding)
                        .size(style.size, alignment: style.horizontalAlignment)
                        .background(style.backgroundColor)
                        .padding(style.margin)
                } else {
                    EmptyView()
                }
            }
        }
    }

}

#if DEBUG

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
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default")

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
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
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
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: .init(
                        states: .init(
                            selected: .init(
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
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .environment(\.componentViewState, .selected)
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
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .environment(\.screenCondition, .medium)
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
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .environment(\.screenCondition, .compact)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Has medium but not medium")

        // Process variable
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
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .environmentObject(PackageContext(
            package: PreviewMock.annualPackage,
            variableContext: .init(packages: [PreviewMock.monthlyPackage, PreviewMock.annualPackage]))
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Process variable")
    }
}

#endif

#endif
