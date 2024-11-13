//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ViewModelFactory.swift
//
//  Created by Josh Holtz on 11/5/24.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ViewModelFactory {

    let packageValidator = PackageValidator()

    func toRootViewModel(
        componentsConfig: PaywallComponentsData.PaywallComponentsConfig,
        offering: Offering,
        localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws -> RootViewModel {
        let rootStackViewModel = try toStackViewModel(
            component: componentsConfig.stack,
            localizedStrings: localizedStrings,
            offering: offering
        )

        let stickyFooterViewModel = try componentsConfig.stickyFooter.flatMap {
            let stackViewModel = try toStackViewModel(
                component: $0.stack,
                localizedStrings: localizedStrings,
                offering: offering
            )

            return StickyFooterComponentViewModel(
                component: $0,
                stackViewModel: stackViewModel
            )
        }

        return RootViewModel(
            stackViewModel: rootStackViewModel,
            stickyFooterViewModel: stickyFooterViewModel
        )
    }

    // swiftlint:disable:next function_body_length
    func toViewModel(
        component: PaywallComponent,
        packageValidator: PackageValidator,
        offering: Offering,
        localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws -> PaywallComponentViewModel {
        switch component {
        case .text(let component):
            return .text(
                try TextComponentViewModel(localizedStrings: localizedStrings, component: component)
            )
        case .image(let component):
            return .image(
                try ImageComponentViewModel(localizedStrings: localizedStrings, component: component)
            )
        case .spacer(let component):
            return .spacer(
                SpacerComponentViewModel(component: component)
            )
        case .stack(let component):
            let viewModels = try component.components.map { component in
                try self.toViewModel(component: component,
                                     packageValidator: packageValidator,
                                     offering: offering,
                                     localizedStrings: localizedStrings)
            }

            return .stack(
                try StackComponentViewModel(component: component,
                                            viewModels: viewModels)
            )
        case .linkButton(let component):
            return .linkButton(
                try LinkButtonComponentViewModel(component: component,
                                                 localizedStrings: localizedStrings)
            )
        case .button(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizedStrings: localizedStrings,
                offering: offering
            )

            return .button(
                try ButtonComponentViewModel(
                    component: component,
                    localizedStrings: localizedStrings,
                    offering: offering,
                    stackViewModel: stackViewModel
                )
            )
        case .package(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizedStrings: localizedStrings,
                offering: offering
            )

            let viewModel = PackageComponentViewModel(
                localizedStrings: localizedStrings,
                component: component,
                offering: offering,
                stackViewModel: stackViewModel
            )

            if let package = viewModel.package {
                packageValidator.add(package, isSelectedByDefault: viewModel.isSelectedByDefault)
            }

            return .package(viewModel)
        case .purchaseButton(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizedStrings: localizedStrings,
                offering: offering
            )

            return .purchaseButton(
                PurchaseButtonComponentViewModel(stackViewModel: stackViewModel)
            )
        case .stickyFooter(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizedStrings: localizedStrings,
                offering: offering
            )

            return .stickyFooter(
                StickyFooterComponentViewModel(
                    component: component,
                    stackViewModel: stackViewModel
                )
            )
        }
    }

    func toStackViewModel(
        component: PaywallComponent.StackComponent,
        localizedStrings: PaywallComponent.LocalizationDictionary,
        offering: Offering
    ) throws -> StackComponentViewModel {
        let viewModels = try component.components.map { component in
            try self.toViewModel(
                component: component,
                packageValidator: packageValidator,
                offering: offering,
                localizedStrings: localizedStrings
            )
        }

        return try StackComponentViewModel(
            component: component,
            viewModels: viewModels
        )
    }

}

#endif
