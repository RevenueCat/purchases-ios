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
// @PublicForExternalTesting
enum PaywallComponentViewModel {

    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case spacer(SpacerComponentViewModel)
    case stack(StackComponentViewModel)
    case linkButton(LinkButtonComponentViewModel)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent {

    func toViewModel(
        offering: Offering,
        localizationProvider: LocalizationProvider
    ) throws -> PaywallComponentViewModel {
        switch self {
        case .text(let component):
            return .text(
                try TextComponentViewModel(
                    localizationProvider: localizationProvider,
                    component: component
                )
            )
        case .image(let component):
            return .image(
                try ImageComponentViewModel(
                    localizationProvider: localizationProvider,
                    component: component
                )
            )
        case .spacer(let component):
            return .spacer(
                SpacerComponentViewModel(component: component)
            )
        case .stack(let component):
            return .stack(
                try StackComponentViewModel(
                    component: component,
                    localizationProvider: localizationProvider,
                    offering: offering
                )
            )
        case .linkButton(let component):
            return .linkButton(
                try LinkButtonComponentViewModel(
                    component: component,
                    localizationProvider: localizationProvider
                )
            )
        }
    }

}

#endif
