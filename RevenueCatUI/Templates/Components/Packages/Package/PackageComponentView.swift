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

    private var componentViewState: ComponentViewState {
        guard let selectedPackage = paywallState.selectedPackage,
                let package = viewModel.package else {
            return .default
        }

        return selectedPackage.identifier == package.identifier ? .selected : .default
    }

    var body: some View {
        if let package = self.viewModel.package {
            Button {
                self.paywallState.select(package: package)
            } label: {
                StackComponentView(
                    viewModel: self.viewModel.stackViewModel,
                    onDismiss: self.onDismiss
                )
                .environment(\.componentViewState, componentViewState)
            }
        } else {
            EmptyView()
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageComponentView_Previews: PreviewProvider {

    static var package: Package {
        return .init(identifier: "weekly",
                     packageType: .weekly,
                     storeProduct: .init(sk1Product: .init()),
                     offeringIdentifier: "default")
    }

    static let paywallState = PaywallState(selectedPackage: nil)
    static let paywallStateSelected = PaywallState(selectedPackage: package)

    static var stack: PaywallComponent.StackComponent {
        return .init(
            components: [
                .text(.init(
                    text: "name",
                    fontWeight: .bold,
                    color: .init(light: .hex("#000000")),
                    padding: .zero,
                    margin: .zero,
                    overrides: .init(
                        states: .init(
                            selected: .init(
                                color: .init(light: .hex("#ff0000"))
                            )
                        )
                    )
                )),
                .text(.init(
                    text: "detail",
                    color: .init(light: .hex("#000000")),
                    padding: .zero,
                    margin: .zero
                ))
            ],
            dimension: .vertical(.leading, .start),
            spacing: 0,
            backgroundColor: nil,
            padding: .init(top: 10,
                           bottom: 10,
                           leading: 20,
                           trailing: 20),
            margin: .init(top: 10,
                          bottom: 10,
                          leading: 10,
                          trailing: 10),
            border: .init(color: .init(light: .hex("#cccccc")), width: 2),
            overrides: .init(
                states: .init(
                    selected: .init(
                        border: .init(color: .init(light: .hex("#ff0000")), width: 2)
                    )
                )
            )
        )
    }

    static var previews: some View {
        // Package
        PackageComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    packageID: "weekly",
                    isSelectedByDefault: false,
                    stack: stack
                ),
                localizedStrings: [
                    "name": .string("Weekly"),
                    "detail": .string("Get for $39.99/wk")
                ],
                offering: .init(identifier: "default",
                                serverDescription: "",
                                availablePackages: [package])
            ), onDismiss: {}
        )
        .environmentObject(paywallState)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Package")

        // Package - Selected
        PackageComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    packageID: "weekly",
                    isSelectedByDefault: false,
                    stack: stack
                ),
                localizedStrings: [
                    "name": .string("Weekly"),
                    "detail": .string("Get for $39.99/wk")
                ],
                offering: .init(identifier: "default",
                                serverDescription: "",
                                availablePackages: [package])
            ), onDismiss: {}
        )
        .environmentObject(paywallStateSelected)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Package - Selected")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension PackageComponentViewModel {

    convenience init(
        component: PaywallComponent.PackageComponent,
        localizedStrings: PaywallComponent.LocalizationDictionary,
        offering: Offering
    ) throws {
        let factory = ViewModelFactory()
        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            localizedStrings: localizedStrings,
            offering: offering
        )

        self.init(
            localizedStrings: localizedStrings,
            component: component,
            offering: offering,
            stackViewModel: stackViewModel
        )
    }

}

#endif

#endif
