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
// swiftlint:disable file_length

import Foundation
import RevenueCat

#if !os(macOS) && !os(tvOS) // For Paywalls V2

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
        let firstImageInfo = self.findFullWidthImageViewIfItsTheFirst(.stack(componentsConfig.stack))

        let rootStackViewModel = try toStackViewModel(
            component: componentsConfig.stack,
            packageValidator: self.packageValidator,
            firstImageInfo: firstImageInfo,
            localizationProvider: localizationProvider,
            uiConfigProvider: uiConfigProvider,
            offering: offering
        )

        let stickyFooterViewModel = try componentsConfig.stickyFooter.flatMap {
            let stackViewModel = try toStackViewModel(
                component: $0.stack,
                packageValidator: self.packageValidator,
                firstImageInfo: nil,
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
            stickyFooterViewModel: stickyFooterViewModel,
            firstImageInfo: firstImageInfo
        )
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity function_parameter_count
    func toViewModel(
        component: PaywallComponent,
        packageValidator: PackageValidator,
        firstImageInfo: RootViewModel.FirstImageInfo?,
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
            return .stack(
                try toStackViewModel(
                    component: component,
                    packageValidator: packageValidator,
                    firstImageInfo: firstImageInfo,
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    offering: offering
                )
            )
        case .button(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                packageValidator: packageValidator,
                firstImageInfo: firstImageInfo,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            var sheetStackViewModel: StackComponentViewModel?

            if case let .navigateTo(.sheet(sheet)) = component.action {
                sheetStackViewModel = try toStackViewModel(
                    component: sheet.stack,
                    packageValidator: packageValidator,
                    firstImageInfo: nil,
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    offering: offering
                )
            }

            return .button(
                try ButtonComponentViewModel(
                    component: component,
                    localizationProvider: localizationProvider,
                    offering: offering,
                    stackViewModel: stackViewModel,
                    sheetStackViewModel: sheetStackViewModel
                )
            )
        case .package(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                packageValidator: packageValidator,
                firstImageInfo: firstImageInfo,
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
                firstImageInfo: firstImageInfo,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            return .purchaseButton(
                try PurchaseButtonComponentViewModel(
                    localizationProvider: localizationProvider,
                    component: component,
                    offering: offering,
                    stackViewModel: stackViewModel
                )
            )
        case .stickyFooter(let component):
            let stackViewModel = try toStackViewModel(
                component: component.stack,
                packageValidator: packageValidator,
                firstImageInfo: firstImageInfo,
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
                return try TimelineItemViewModel(
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
                firstImageInfo: firstImageInfo,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider,
                offering: offering
            )

            let tabViewModels: [TabViewModel] = try component.tabs.map { tab in
                let tabPackageValidator = PackageValidator()

                let stackViewModel = try toStackViewModel(
                    component: tab.stack,
                    packageValidator: tabPackageValidator,
                    firstImageInfo: firstImageInfo,
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
                firstImageInfo: firstImageInfo,
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
        case .carousel(let component):
            let pageStackViewModels = try component.pages.map { stackComponent in
                try toStackViewModel(
                    component: stackComponent,
                    packageValidator: packageValidator,
                    firstImageInfo: firstImageInfo,
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    offering: offering
                )
            }

            return .carousel(
                try CarouselComponentViewModel(
                    localizationProvider: localizationProvider,
                    uiConfigProvider: uiConfigProvider,
                    component: component,
                    pageStackViewModels: pageStackViewModels
                )
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    func toStackViewModel(
        component: PaywallComponent.StackComponent,
        packageValidator: PackageValidator,
        firstImageInfo: RootViewModel.FirstImageInfo?,
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        offering: Offering
    ) throws -> StackComponentViewModel {
        let viewModels = try component.components.map { component in
            try self.toViewModel(
                component: component,
                packageValidator: packageValidator,
                firstImageInfo: firstImageInfo,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider
            )
        }

        let badgeViewModels = try component.badge?.stack.components.map { component in
            try self.toViewModel(
                component: component,
                packageValidator: packageValidator,
                firstImageInfo: firstImageInfo,
                offering: offering,
                localizationProvider: localizationProvider,
                uiConfigProvider: uiConfigProvider
            )
        } ?? []

        // Stores in view model that we need to apply the safe area inset
        // This is only used with ZStack children that aren't the background
        let shouldApplySafeAreaInset = component == firstImageInfo?.parentZStack

        return try StackComponentViewModel(
            component: component,
            viewModels: viewModels,
            badgeViewModels: badgeViewModels,
            shouldApplySafeAreaInset: shouldApplySafeAreaInset,
            uiConfigProvider: uiConfigProvider,
            localizationProvider: localizationProvider
        )
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func findFullWidthImageViewIfItsTheFirst(
        _ component: PaywallComponent
    ) -> RootViewModel.FirstImageInfo? {
        switch component {
        case .text:
            return nil
        case .image(let image):
            switch image.size.width {
            case .fill:
                return .init(imageComponent: image, parentZStack: nil)
            case .fit, .fixed, .relative:
                return nil
            }
        case .icon:
            return nil
        case .stack(let stack):
            guard let first = stack.components.first else {
                return nil
            }

            let imageInfo = self.findFullWidthImageViewIfItsTheFirst(first)

            switch stack.dimension {
            case .vertical, .horizontal:
                return imageInfo
            case .zlayer:
                // Return the ZStack info paired with the image
                // This is needed to we know what element to apply safe area too
                return imageInfo.flatMap { info in
                    return .init(imageComponent: info.imageComponent,
                                 parentZStack: stack)
                }
            }
        case .button:
            return nil
        case .package(let package):
            guard let first = package.stack.components.first else {
                return nil
            }
            return self.findFullWidthImageViewIfItsTheFirst(first)
        case .purchaseButton:
            return nil
        case .stickyFooter:
            return nil
        case .timeline:
            return nil
        case .tabs(let tabs):
            guard let first = tabs.tabs.first?.stack.components.first else {
                return nil
            }
            return self.findFullWidthImageViewIfItsTheFirst(first)
        case .tabControl:
            return nil
        case .tabControlButton:
            return nil
        case .tabControlToggle:
            return nil
        case .carousel(let carousel):
            guard let first = carousel.pages.first?.components.first else {
                return nil
            }
            return self.findFullWidthImageViewIfItsTheFirst(first)
        }
    }

}

#endif
