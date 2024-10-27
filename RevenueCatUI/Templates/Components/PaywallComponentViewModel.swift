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

    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case spacer(SpacerComponentViewModel)
    case stack(StackComponentViewModel)
    case linkButton(LinkButtonComponentViewModel)
    case button(ButtonComponentViewModel)
    case package(PackageComponentViewModel)
    case purchaseButton(PurchaseButtonComponentViewModel)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent {

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
            packageValidator.add(viewModel)

            return .package(viewModel)
        case .purchaseButton(let component):
            return .purchaseButton(
                try PurchaseButtonComponentViewModel(packageValidator: packageValidator,
                                                     localizedStrings: localizedStrings,
                                                     component: component,
                                                     offering: offering)
            )
        }
    }

    enum PaywallComponentViewModelError: Error {

        case invalidAttemptToCreatePackage

    }

}

#endif
