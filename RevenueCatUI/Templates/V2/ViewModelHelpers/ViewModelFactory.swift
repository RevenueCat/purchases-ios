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
        localizationProvider: LocalizationProvider
    ) throws -> RootViewModel {
        let rootStackViewModel = try toStackViewModel(
            component: componentsConfig.stack,
            localizationProvider: localizationProvider,
            offering: offering
        )

        let stickyFooterViewModel = try componentsConfig.stickyFooter.flatMap {
            let stackViewModel = try toStackViewModel(
                component: $0.stack,
                localizationProvider: localizationProvider,
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
        localizationProvider: LocalizationProvider
    ) throws -> PaywallComponentViewModel {
        switch component {
        case .text(let component):
            return .text(
                try TextComponentViewModel(localizationProvider: localizationProvider, component: component)
            )
        case .image(let component):
            return .image(
                try ImageComponentViewModel(localizationProvider: localizationProvider, component: component)
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
                                     localizationProvider: localizationProvider)
            }

            return .stack(
                try StackComponentViewModel(component: component,
                                            viewModels: viewModels)
            )
        case .linkButton(let component):
            return .linkButton(
                try LinkButtonComponentViewModel(component: component,
                                                 localizationProvider: localizationProvider)
            )
        case .button(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizationProvider: localizationProvider,
                offering: offering
            )

            return .button(
                try ButtonComponentViewModel(
                    component: component,
                    localizationProvider: localizationProvider,
                    offering: offering,
                    stackViewModel: stackViewModel
                )
            )
        case .package(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizationProvider: localizationProvider,
                offering: offering
            )

            let viewModel = PackageComponentViewModel(
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
                localizationProvider: localizationProvider,
                offering: offering
            )

            return .purchaseButton(
                PurchaseButtonComponentViewModel(stackViewModel: stackViewModel)
            )
        case .stickyFooter(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                localizationProvider: localizationProvider,
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
        localizationProvider: LocalizationProvider,
        offering: Offering
    ) throws -> StackComponentViewModel {
        let viewModels = try component.components.map { component in
            try self.toViewModel(
                component: component,
                packageValidator: packageValidator,
                offering: offering,
                localizationProvider: localizationProvider
            )
        }

        return try StackComponentViewModel(
            component: component,
            viewModels: viewModels
        )
    }

}

#endif
