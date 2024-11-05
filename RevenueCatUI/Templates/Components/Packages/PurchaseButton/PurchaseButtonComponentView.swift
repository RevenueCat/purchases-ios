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

    @EnvironmentObject
    private var paywallState: PaywallState

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    private let viewModel: PurchaseButtonComponentViewModel

    internal init(viewModel: PurchaseButtonComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        AsyncButton {
            guard !self.purchaseHandler.actionInProgress else { return }

            // WIP: Need to log warning if currently subscribed
            guard let selectedPackage = self.paywallState.selectedPackage
//                    , selectedPackage.currentlySubscribed
            else {
                Logger.warning(Strings.product_already_subscribed)
                return
            }

            _ = try await self.purchaseHandler.purchase(package: selectedPackage)
        } label: {
            // Not passing an onDismiss - nothing in this stack should be able to dismiss
            StackComponentView(viewModel: viewModel.stackViewModel, onDismiss: {})
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
                packageValidator: PackageValidator(),
                localizedStrings: [
                    "id_1": .string("Hello, world"),
                    "id_2": .string("Hello, world intro offer")
                ],
                component: .init(
                    stack: .init(components: [
                        // WIP: Intro offer state with "id_2",
                        .text(.init(
                            text: "id_1",
                            fontWeight: .bold,
                            color: .init(light: "#ffffff"),
                            backgroundColor: .init(light: "#ff0000"),
                            padding: .init(top: 10,
                                           bottom: 10,
                                           leading: 30,
                                           trailing: 30)
                        ))
                    ])
                ),
                offering: Offering(identifier: "",
                                   serverDescription: "",
                                   availablePackages: [])
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Pill")

        // Rounded Rectangle
        PurchaseButtonComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                packageValidator: PackageValidator(),
                localizedStrings: [
                    "id_1": .string("Hello, world"),
                    "id_2": .string("Hello, world intro offer")
                ],
                component: .init(
                    stack: .init(
                        components: [
                            // WIP: Intro offer state with "id_2",
                            .text(.init(
                                text: "id_1",
                                fontWeight: .bold,
                                color: .init(light: "#ffffff")
                            ))
                        ],
                        backgroundColor: .init(light: "#ff0000"),
                        padding: .init(top: 8,
                                       bottom: 8,
                                       leading: 8,
                                       trailing: 8),
                        cornerRadiuses: PaywallComponent.CornerRadiuses(
                            topLeading: 8,
                            topTrailing: 8,
                            bottomLeading: 8,
                            bottomTrailing: 8
                        )
                    )
                ),
                offering: Offering(identifier: "",
                                   serverDescription: "",
                                   availablePackages: [])
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Rounded Rectangle")
    }
}

#endif

#endif
