//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseButtonComponentView.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView: View {

    private let viewModel: PurchaseButtonComponentViewModel

    internal init(viewModel: PurchaseButtonComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button {
            // WIP: Need to perform purchase logic
        } label: {
            // WIP: Need to add logic for intro offer
            Text(viewModel.cta)
                .font(viewModel.textStyle)
                .fontWeight(viewModel.fontWeight)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(viewModel.horizontalAlignment)
                .foregroundStyle(viewModel.color)
                .padding(viewModel.padding)
                .background(viewModel.backgroundColor)
                .shape(viewModel.clipShape)
                .cornerBorder(border: nil,
                              radiuses: viewModel.cornerRadiuses)                .padding(viewModel.margin)
        }
    }

}

private struct ShapeModifier: ViewModifier {
    var shape: PaywallComponent.Shape

    func body(content: Content) -> some View {
        switch shape {
        case .pill:
            content
                .clipShape(Capsule())
        case .rectangle:
            content
        }
    }
}

private extension View {

    func shape(_ shape: PaywallComponent.Shape) -> some View {
        self.modifier(ShapeModifier(shape: shape))
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PurchaseButtonComponentView_Previews: PreviewProvider {

    static var previews: some View {
        // Pill
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world"),
                    "id_2": .string("Hello, world intro offer")
                ],
                component: .init(
                    cta: "id_1",
                    ctaIntroOffer: "id_2",
                    fontWeight: .bold,
                    color: .init(light: "#ffffff"),
                    backgroundColor: .init(light: "#ff0000"),
                    padding: .init(top: 10,
                                   bottom: 10,
                                   leading: 30,
                                   trailing: 30),
                    shape: .pill
                )
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Pill")

        // Rounded Rectangle
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world"),
                    "id_2": .string("Hello, world intro offer")
                ],
                component: .init(
                    cta: "id_1",
                    ctaIntroOffer: "id_2",
                    fontWeight: .bold,
                    color: .init(light: "#ffffff"),
                    backgroundColor: .init(light: "#ff0000"),
                    padding: .init(top: 10,
                                   bottom: 10,
                                   leading: 30,
                                   trailing: 30),
                    shape: .rectangle,
                    cornerRadiuses: .init(topLeading: 8,
                                          topTrailing: 8,
                                          bottomLeading: 8,
                                          bottomTrailing: 8)
                )
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Rounded Rectangle")
    }
}

#endif

#endif
