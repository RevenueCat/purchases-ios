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
    private var packageContext: PackageContext

    let viewModel: PackageComponentViewModel
    let onDismiss: () -> Void

    private var componentViewState: ComponentViewState {
        // Gets selected package context from parent heirarchy
        guard let selectedPackage = packageContext.package,
                let package = viewModel.package else {
            return .default
        }

        return selectedPackage.identifier == package.identifier ? .selected : .default
    }

    var body: some View {
        if let package = self.viewModel.package {
            Button {
                // Updating package with same variable context
                // This will be needed when different sets of packages
                // in different tiers
                self.packageContext.update(
                    package: package,
                    variableContext: self.packageContext.variableContext
                )
            } label: {
                StackComponentView(
                    viewModel: self.viewModel.stackViewModel,
                    onDismiss: self.onDismiss
                )
                .environment(\.componentViewState, componentViewState)
                // Overrides the existing PackageContext
                .environmentObject(PackageContext(
                    // This is needed so text component children use this
                    // package and not selected package for processing variables
                    package: package,
                    // However, reusing the same package variable context from parent
                    variableContext: packageContext.variableContext)
                )
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

    static let packageContext = PackageContext(
        package: nil,
        variableContext: .init()
    )
    static let packageContextSelected = PackageContext(
        package: Self.package,
        variableContext: .init()
    )

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
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "name": .string("Weekly"),
                        "detail": .string("Get for $39.99/wk")
                    ]
                ),
                offering: .init(identifier: "default",
                                serverDescription: "",
                                availablePackages: [package])
            ), onDismiss: {}
        )
        .previewRequiredEnvironmentProperties(
            packageContext: packageContext
        )
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
                localizationProvider: .init(
                    locale: Locale.current,
                    localizedStrings: [
                        "name": .string("Weekly"),
                        "detail": .string("Get for $39.99/wk")
                    ]
                ),
                offering: .init(identifier: "default",
                                serverDescription: "",
                                availablePackages: [package])
            ), onDismiss: {}
        )
        .previewRequiredEnvironmentProperties(
            packageContext: packageContextSelected
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Package - Selected")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
fileprivate extension PackageComponentViewModel {

    convenience init(
        component: PaywallComponent.PackageComponent,
        localizationProvider: LocalizationProvider,
        offering: Offering
    ) throws {
        let factory = ViewModelFactory()
        let stackViewModel = try factory.toStackViewModel(
            component: component.stack,
            localizationProvider: localizationProvider,
            offering: offering
        )

        self.init(
            component: component,
            offering: offering,
            stackViewModel: stackViewModel
        )
    }

}

#endif

#endif
