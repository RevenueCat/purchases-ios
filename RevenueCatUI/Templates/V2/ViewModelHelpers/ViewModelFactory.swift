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
// swiftlint:disable:next type_body_length
struct ViewModelFactory {

    let packageValidator = PackageValidator()

    func toRootViewModel(
        componentsConfig: PaywallComponentsData.PaywallComponentsConfig,
        offering: Offering,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider
    ) throws -> RootViewModel {
        let rootStackViewModel = try toStackViewModel(
            component: componentsConfig.stack,
            packageValidator: self.packageValidator,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering
        )

        let stickyFooterViewModel = try componentsConfig.stickyFooter.flatMap {
            let stackViewModel = try toStackViewModel(
                component: $0.stack,
                packageValidator: self.packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func toViewModel(
        component: PaywallComponent,
        packageValidator: PackageValidator,
        offering: Offering,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider
    ) throws -> PaywallComponentViewModel {
        switch component {
        case .text(let component):
            return .text(
                try TextComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: component
                )
            )
        case .image(let component):
            return .image(
                try ImageComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: component
                )
            )
        case .icon(let component):
            return .icon(
                try IconComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: component
                )
            )
        case .stack(let component):
            let viewModels = try component.components.map { component in
                try self.toViewModel(
                    component: component,
                    packageValidator: packageValidator,
                    offering: offering,
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider
                )
            }

            let badgeViewModels = try component.badge?.stack.value.components.map { component in
                try self.toViewModel(
                    component: component,
                    packageValidator: packageValidator,
                    offering: offering,
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider
                )
            }

            return .stack(
                try StackComponentViewModel(component: component,
                                            viewModels: viewModels,
                                            badgeViewModels: badgeViewModels ?? [],
                                            uiConfigProvider: uiConfigProvider,
                                            localizationProvider: localizationProvider)
            )
        case .button(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                packageValidator: packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
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
                packageValidator: packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
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
                packageValidator: packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            return .purchaseButton(
                PurchaseButtonComponentViewModel(stackViewModel: stackViewModel)
            )
        case .stickyFooter(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                packageValidator: packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            return .stickyFooter(
                StickyFooterComponentViewModel(
                    component: component,
                    stackViewModel: stackViewModel
                )
            )
        case .timeline(let component):
            let models = try component.items.map { item in
                var description: TextComponentViewModel?
                if let descriptionComponent = item.description {
                    description = try TextComponentViewModel(
                        localizationProvider: localizationProvider,
                        uiConfigProvider: uiConfigProvider,
                        component: descriptionComponent
                    )
                }
                return TimelineItemViewModel(
                    component: item,
                    title: try TextComponentViewModel(
                        localizationProvider: localizationProvider,
                        uiConfigProvider: uiConfigProvider,
                        component: item.title
                    ),
                    description: description,
                    icon: try IconComponentViewModel(
                        localizationProvider: localizationProvider,
                        uiConfigProvider: uiConfigProvider,
                        component: item.icon
                    )
                )
            }

            return .timeline(
                try TimelineComponentViewModel(
                    component: component,
                    items: models,
                    uiConfigProvider: uiConfigProvider
                )
            )
        case .tabs(let component):
            let controlStackViewModel = try toStackViewModel(
                component: component.control.stack,
                packageValidator: packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            let tabViewModels: [TabViewModel] = try component.tabs.map { tab in
                let tabPackageValidator = PackageValidator()

                let stackViewModel = try toStackViewModel(
                    component: tab.stack,
                    packageValidator: tabPackageValidator,
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    offering: offering
                )

                // Merging into entire paywall package validator
                for (pkg, isSelectedByDefault) in tabPackageValidator.packageInfos {
                    packageValidator.add(pkg, isSelectedByDefault: isSelectedByDefault)
                }

                return try .init(
                    tab: tab,
                    stackViewModel: stackViewModel,
                    defaultSelectedPackage: tabPackageValidator.defaultSelectedPackage,
                    packages: tabPackageValidator.packages,
                    uiConfigProvider: uiConfigProvider
                )
            }

            return .tabs(
                try TabsComponentViewModel(
                    component: component,
                    controlStackViewModel: controlStackViewModel,
                    tabViewModels: tabViewModels,
                    uiConfigProvider: uiConfigProvider
                )
            )
        case .tabControl(let component):
            return .tabControl(
                try TabControlComponentViewModel(
                    component: component,
                    uiConfigProvider: uiConfigProvider
                )
            )
        case .tabControlButton(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                packageValidator: packageValidator,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            return .tabControlButton(
                try TabControlButtonComponentViewModel(
                    component: component,
                    stackViewModel: stackViewModel,
                    uiConfigProvider: uiConfigProvider
                )
            )
        case .tabControlToggle(let component):
            return .tabControlToggle(
                try TabControlToggleComponentViewModel(
                    component: component,
                    uiConfigProvider: uiConfigProvider
                )
            )
        }
    }

    func toStackViewModel(
        component: PaywallComponent.StackComponent,
        packageValidator: PackageValidator,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        offering: Offering
    ) throws -> StackComponentViewModel {
        let viewModels = try component.components.map { component in
            try self.toViewModel(
                component: component,
                packageValidator: packageValidator,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider
            )
        }

        return try StackComponentViewModel(
            component: component,
            viewModels: viewModels,
            badgeViewModels: [],
            uiConfigProvider: uiConfigProvider,
            localizationProvider: localizationProvider
        )
    }

}

#endif
