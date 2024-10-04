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

    private let viewModel: TextComponentViewModel

    internal init(viewModel: TextComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(viewModel.text)
            .font(viewModel.textStyle)
            .fontWeight(viewModel.fontWeight)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(viewModel.horizontalAlignment)
            .foregroundStyle(viewModel.color)
            .padding(viewModel.padding)
            .background(viewModel.backgroundColor)
            .padding(viewModel.margin)
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
                    color: .init(light: "#000000")
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
                    fontFamily: nil,
                    fontWeight: .heavy,
                    color: .init(light: "#ff0000"),
                    backgroundColor: .init(light: "#dedede"),
                    padding: .init(top: 10,
                                   bottom: 10,
                                   leading: 20,
                                   trailing: 20),
                    margin: .init(top: 20,
                                  bottom: 20,
                                  leading: 10,
                                  trailing: 10),
                    textStyle: .footnote,
                    horizontalAlignment: .leading
                )
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Customizations")
    }
}

#endif

#endif
