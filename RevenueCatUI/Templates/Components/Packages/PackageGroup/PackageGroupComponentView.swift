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

    let viewModel: PackageGroupComponentViewModel

    var body: some View {
        // TODO: Do something with default package id and selection
        StackComponentView(viewModel: self.viewModel.stackComponentViewModel)
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackagesComponentView_Previews: PreviewProvider {

    static let packages: [PaywallComponent] = [
        makePackage(packageID: "weekly",
                    nameTextLid: "weekly_name",
                    detailTextLid: "weekly_detail"),
        makePackage(packageID: "monthly",
                    nameTextLid: "monthly_name",
                    detailTextLid: "monthly_detail")
    ]

    static func makePackage(packageID: String,
                            nameTextLid: String,
                            detailTextLid: String) -> PaywallComponent {
        let stack: PaywallComponent = .stack(.init(
            components: [
                .text(.init(
                    textLid: nameTextLid,
                    fontWeight: .bold,
                    color: .init(light: "#000000"),
                    padding: .zero,
                    margin: .zero
                )),
                .text(.init(
                    textLid: detailTextLid,
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

        return .package(.init(
            packageID: "weekly",
            components: [stack]
        ))
    }

    static var previews: some View {
        // Packages
        PackageGroupComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "weekly_name": .string("Weekly"),
                    "weekly_detail": .string("Get for $39.99/week"),
                    "monthly_name": .string("Monthly"),
                    "monthly_detail": .string("Get for $139.99/month")
                ],
                component: PaywallComponent.PackageGroupComponent(
                    defaultSelectedPackageID: "weekly",
                    components: packages
                ),
                offering: Offering(identifier: "",
                                serverDescription: "",
                                availablePackages: [])
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Packages")
    }
}

#endif

#endif
