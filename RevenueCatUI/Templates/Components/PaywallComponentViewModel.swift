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
    case packageGroup(PackageGroupComponentViewModel)
    // Purposely leaving out a `case package` since `PackageGroupComponentViewModel` creates this model
    case purchaseButton(PurchaseButtonComponentViewModel)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent {

    func toViewModel(
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
                try StackComponentViewModel(component: component,
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
                    component: component,
                    localizedStrings: localizedStrings,
                    offering: offering
                )
            )
        case .packageGroup(let component):
            return .packageGroup(
                try PackageGroupComponentViewModel(localizedStrings: localizedStrings,
                                                   component: component,
                                                   offering: offering)
            )
        case .package:
            // PackageGroupViewModel makes the PackageViewModel since it needs a Package
            throw PaywallComponentViewModelError.invalidAttemptToCreatePackage
        case .purchaseButton(let component):
            return .purchaseButton(
                try PurchaseButtonComponentViewModel(localizedStrings: localizedStrings,
                                                     component: component)
            )
        }
    }

    enum PaywallComponentViewModelError: Error {

        case invalidAttemptToCreatePackage

    }

}

#endif
