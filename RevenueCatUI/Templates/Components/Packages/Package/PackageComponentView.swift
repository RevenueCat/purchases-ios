//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentView.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageComponentView: View {

    @EnvironmentObject
    private var paywallState: PaywallState

    let viewModel: PackageComponentViewModel
    let onDismiss: () -> Void

    var body: some View {
        // WIP: Do something with package id and selection
        StackComponentView(viewModel: self.viewModel.stackComponentViewModel,
                           onDismiss: self.onDismiss)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageComponentView_Previews: PreviewProvider {

    static var components: [PaywallComponent] = [
        .stack(.init(
            components: [
                .text(.init(
                    text: "name",
                    fontWeight: .bold,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                )),
                .text(.init(
                    text: "detail",
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                ))
            ],
            dimension: .vertical(.leading),
            spacing: 0,
            backgroundColor: nil,
            padding: .init(top: 10,
                           bottom: 10,
                           leading: 20,
                           trailing: 20)
        ))
    ]

    static var previews: some View {
        // Package
        PackageComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "name": .string("Weekly"),
                    "detail": .string("Get for $39.99/wk")
                ],
                component: .init(
                    packageID: "weekly",
                    components: components
                ),
                offering: .init(identifier: "default",
                                serverDescription: "",
                                availablePackages: [
                                    .init(identifier: "weekly",
                                          packageType: .weekly,
                                          storeProduct: .init(sk1Product: .init()),
                                          offeringIdentifier: "default")])
            ), onDismiss: {}
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Package")
    }
}

#endif

#endif
