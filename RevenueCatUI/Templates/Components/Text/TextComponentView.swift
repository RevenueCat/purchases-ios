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
            condition: self.screenCondition
        ) { style in
            Group {
                if style.visible {
                    Text(style.text)
                        .font(style.fontSize)
                        .fontWeight(style.fontWeight)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(style.horizontalAlignment)
                        .foregroundStyle(style.color)
                        .padding(style.padding)
                        .size(style.size)
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
                localizedStrings: [
                    "id_1": .string("Hello, world")
                ],
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default")

        // Customizations
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world")
                ],
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
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Customizations")

        // State - Selected
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world")
                ],
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
        .environment(\.componentViewState, .selected)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("State - Selected")

        // Condition - Medium
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("THIS TEXT SHOULDN'T SHOW"),
                    "id_2": .string("Showing medium condition")
                ],
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
        .environment(\.screenCondition, .medium)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Medium")

        // Condition - Has medium but not medium
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Showing compact condition"),
                    "id_2": .string("SHOULDN'T SHOW MEDIUM")
                ],
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
        .environment(\.screenCondition, .compact)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Has medium but not medium")
    }
}

#endif

#endif
