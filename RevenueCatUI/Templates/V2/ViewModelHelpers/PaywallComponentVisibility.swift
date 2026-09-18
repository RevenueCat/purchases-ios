//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
struct PaywallComponentVisibilityContext {

    let componentViewState: ComponentViewState
    let screenCondition: ScreenCondition
    let packageContext: PackageContext
    let introOfferEligibilityContext: IntroOfferEligibilityContext
    let paywallPromoOfferCache: PaywallPromoOfferCache
    let selectedPackageId: String?
    let customVariables: [String: CustomVariableValue]
    let stateValues: [String: PaywallComponent.ConditionValue]
    let stateDefaults: [String: PaywallComponent.ConditionValue]
    let windowSize: CGSize?
    let colorScheme: ColorScheme

    func isEligibleForIntroOffer(package: Package?) -> Bool {
        return self.introOfferEligibilityContext.isEligible(package: package)
    }

    func isEligibleForPromoOffer(package: Package?) -> Bool {
        return self.paywallPromoOfferCache.isMostLikelyEligible(for: package)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct IdentifiedPaywallComponentViewModel: Identifiable {

    let id: Int
    let viewModel: PaywallComponentViewModel

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
extension PaywallComponentViewModel {

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func isVisible(in context: PaywallComponentVisibilityContext) -> Bool {
        let package = context.packageContext.package
        let isEligibleForIntroOffer = context.isEligibleForIntroOffer(package: package)
        let isEligibleForPromoOffer = context.isEligibleForPromoOffer(package: package)

        switch self {
        case .root, .purchaseButton, .tabControl, .tabControlButton, .tabControlToggle, .countdown:
            return true
        case .stickyFooter:
            return false
        case .text(let viewModel):
            return viewModel.visible(
                state: context.componentViewState,
                condition: context.screenCondition,
                selectedPackageId: context.selectedPackageId,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: context.paywallPromoOfferCache.get(for: package) != nil,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize
            )
        case .image(let viewModel):
            return viewModel.styles(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize,
                colorScheme: context.colorScheme
            ).visible
        case .icon(let viewModel):
            return viewModel.visible(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize
            )
        case .stack(let viewModel):
            return viewModel.styles(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize,
                colorScheme: context.colorScheme
            ).visible
        case .button(let viewModel):
            return !viewModel.hasUnknownAction && viewModel.visible(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize
            )
        case .package(let viewModel):
            guard let childPackage = viewModel.package else {
                return false
            }

            let state: ComponentViewState = package?.identifier == childPackage.identifier ? .selected : .default
            return viewModel.visible(
                state: state,
                condition: context.screenCondition,
                isEligibleForIntroOffer: context.isEligibleForIntroOffer(package: childPackage),
                isEligibleForPromoOffer: context.isEligibleForPromoOffer(package: childPackage),
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize
            )
        case .timeline(let viewModel):
            return viewModel.visible(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize
            )
        case .tabs(let viewModel):
            return viewModel.styles(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize,
                colorScheme: context.colorScheme
            ).visible
        case .carousel(let viewModel):
            return viewModel.visible(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize
            )
        case .video(let viewModel):
            return viewModel.visible(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize
            )
        case .webView(let viewModel):
            return viewModel.style(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize
            ).visible
        }
    }

}

#endif
