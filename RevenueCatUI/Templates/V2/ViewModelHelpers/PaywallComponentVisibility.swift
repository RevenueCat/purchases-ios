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

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallComponentVisibilityResolver {

    typealias PromoOfferEligibility = @MainActor (PaywallComponentVisibilityContext, Package?) -> Bool

    private let resolve: @MainActor (PaywallComponentVisibilityContext) -> Bool

    init<Partial: PresentedPartial>(
        _ baseVisible: Bool?,
        _ uiConfigProvider: UIConfigProvider,
        _ presentedOverrides: PresentedOverrides<Partial>?,
        promoOfferEligibility: @escaping PromoOfferEligibility = { context, package in
            context.paywallPromoOfferCache.isMostLikelyEligible(for: package)
        },
        visible: @escaping (Partial) -> Bool?
    ) {
        self.resolve = { context in
            let package = context.packageContext.package
            let conditionContext = uiConfigProvider.conditionContext(
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                stateValues: context.stateValues,
                stateDefaults: context.stateDefaults,
                windowSize: context.windowSize
            )
            let partial = Partial.buildPartial(
                state: context.componentViewState,
                condition: context.screenCondition,
                isEligibleForIntroOffer: context.introOfferEligibilityContext.isEligible(package: package),
                isEligibleForPromoOffer: promoOfferEligibility(context, package),
                conditionContext: conditionContext,
                with: presentedOverrides
            )

            return partial.flatMap(visible) ?? baseVisible ?? true
        }
    }

    @MainActor
    func isVisible(in context: PaywallComponentVisibilityContext) -> Bool {
        return self.resolve(context)
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
        let isEligibleForIntroOffer = context.introOfferEligibilityContext.isEligible(package: package)
        let isEligibleForPromoOffer = context.paywallPromoOfferCache.isMostLikelyEligible(for: package)

        switch self {
        case .root, .purchaseButton, .tabControl, .tabControlButton, .tabControlToggle, .countdown:
            return true
        case .stickyFooter:
            return false
        case .text(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .image(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .icon(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .stack(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
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
                isEligibleForIntroOffer: context.introOfferEligibilityContext.isEligible(package: childPackage),
                isEligibleForPromoOffer: context.paywallPromoOfferCache.isMostLikelyEligible(for: childPackage),
                selectedPackageId: context.selectedPackageId,
                customVariables: context.customVariables,
                windowSize: context.windowSize
            )
        case .timeline(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .tabs(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .carousel(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .video(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        case .webView(let viewModel): return viewModel.visibilityResolver.isVisible(in: context)
        }
    }

}

#endif
