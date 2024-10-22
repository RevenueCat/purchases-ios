//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageGroupComponentView.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageGroupComponentView: View {

    @EnvironmentObject
    private var paywallState: PaywallState

    let viewModel: PackageGroupComponentViewModel
    let onDismiss: () -> Void

    var body: some View {
        // WIP: Do something with default package id and selection
        StackComponentView(viewModel: viewModel.stackViewModel, onDismiss: self.onDismiss)
        .onAppear {
            self.paywallState.select(package: self.viewModel.defaultPackage)
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackagesComponentView_Previews: PreviewProvider {

    static let paywallState = PaywallState()

    static let packages: [PaywallComponent.PackageComponent] = [
        makePackage(packageID: "weekly",
                    nameTextLid: "weekly_name",
                    detailTextLid: "weekly_detail"),
        makePackage(packageID: "non_existant_package",
                    nameTextLid: "non_existant_name",
                    detailTextLid: "non_existant_detail"),
        makePackage(packageID: "monthly",
                    nameTextLid: "monthly_name",
                    detailTextLid: "monthly_detail")
    ]

    static func makePackage(packageID: String,
                            nameTextLid: String,
                            detailTextLid: String) -> PaywallComponent.PackageComponent {
        let stack: PaywallComponent.StackComponent = .init(
            components: [
                .text(.init(
                    text: nameTextLid,
                    fontWeight: .bold,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                )),
                .text(.init(
                    text: detailTextLid,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                ))
            ],
            dimension: .vertical(.leading),
            spacing: 0,
            backgroundColor: nil,
            padding: PaywallComponent.Padding(top: 10,
                                              bottom: 10,
                                              leading: 20,
                                              trailing: 20)
        )

        return PaywallComponent.PackageComponent(
            packageID: packageID,
            stack: stack
        )
    }

    static var previews: some View {
        // Packages
        PackageGroupComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! PackageGroupComponentViewModel(
                localizedStrings: [
                    "weekly_name": .string("Weekly"),
                    "weekly_detail": .string("Get for $39.99/week"),
                    "monthly_name": .string("Monthly"),
                    "monthly_detail": .string("Get for $139.99/month"),
                    "non_existant_name": .string("THIS SHOULDN'T SHOW"),
                    "non_existant_detail": .string("THIS SHOULDN'T SHOW")

                ],
                component: PaywallComponent.PackageGroupComponent(
                    defaultSelectedPackageID: "weekly",
                    stack: .init(components: packages)
                ),
                offering: Offering(identifier: "default",
                                   serverDescription: "",
                                   availablePackages: [
                                    Package(identifier: "weekly",
                                            packageType: .weekly,
                                            storeProduct: .init(sk1Product: .init()),
                                            offeringIdentifier: "default"),
                                    Package(identifier: "monthly",
                                            packageType: .monthly,
                                            storeProduct: .init(sk1Product: .init()),
                                            offeringIdentifier: "default")
                                   ])
            ), onDismiss: {}
        )
        .environmentObject(paywallState)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Packages")
    }
}

#endif

#endif
