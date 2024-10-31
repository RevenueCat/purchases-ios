//
//  PaywallComponentViewModel.swift
//
//
//  Created by James Borthwick on 2024-08-29.
//

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallComponentViewModel {

    case root(RootViewModel)
    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case spacer(SpacerComponentViewModel)
    case stack(StackComponentViewModel)
    case linkButton(LinkButtonComponentViewModel)
    case button(ButtonComponentViewModel)
    case package(PackageComponentViewModel)
    case purchaseButton(PurchaseButtonComponentViewModel)
    case stickyFooter(StickyFooterComponentViewModel)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent {

    // swiftlint:disable:next function_body_length
    func toViewModel(
        packageValidator: PackageValidator,
        offering: Offering,
        localizedStrings: LocalizationDictionary
    ) throws -> PaywallComponentViewModel {
        switch self {
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
            return .stack(
                try StackComponentViewModel(packageValidator: packageValidator,
                                            component: component,
                                            localizedStrings: localizedStrings,
                                            offering: offering)
            )
        case .linkButton(let component):
            return .linkButton(
                try LinkButtonComponentViewModel(component: component,
                                                 localizedStrings: localizedStrings)
            )
        case .button(let component):
            return .button(
                try ButtonComponentViewModel(
                    packageValidator: packageValidator,
                    component: component,
                    localizedStrings: localizedStrings,
                    offering: offering
                )
            )
        case .package(let component):
            let viewModel = try PackageComponentViewModel(packageValidator: packageValidator,
                                                          localizedStrings: localizedStrings,
                                                          component: component,
                                                          offering: offering)

            if let package = viewModel.package {
                packageValidator.add(package, isSelectedByDefault: viewModel.isSelectedByDefault)
            }

            return .package(viewModel)
        case .purchaseButton(let component):
            return .purchaseButton(
                try PurchaseButtonComponentViewModel(packageValidator: packageValidator,
                                                     localizedStrings: localizedStrings,
                                                     component: component,
                                                     offering: offering)
            )
        case .stickyFooter(let component):
            return .stickyFooter(
                try StickyFooterComponentViewModel(
                    component: component,
                    stackViewModel: StackComponentViewModel(
                        packageValidator: packageValidator,
                        component: component.stack,
                        localizedStrings: localizedStrings,
                        offering: offering
                    )
                )
            )
        }
    }

    enum PaywallComponentViewModelError: Error {

        case invalidAttemptToCreatePackage

    }

}

#endif
