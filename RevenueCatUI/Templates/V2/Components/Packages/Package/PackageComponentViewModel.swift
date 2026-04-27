//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentViewModel.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

typealias PresentedPackagePartial = PaywallComponent.PartialPackageComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageComponentViewModel {

    let isSelectedByDefault: Bool
    let promotionalOfferProductCode: String?
    let componentName: String?
    let package: Package?
    let stackViewModel: StackComponentViewModel
    let hasPurchaseButton: Bool

    private let componentVisible: Bool?
    private let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedPackagePartial>?

    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel,
        hasPurchaseButton: Bool,
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool = false
    ) {
        self.componentVisible = component.visible
        self.uiConfigProvider = uiConfigProvider
        self.isSelectedByDefault = component.isSelectedByDefault
        self.promotionalOfferProductCode = component.applePromoOfferProductCode
        self.componentName = component.name

        self.package = offering.package(identifier: component.packageID)
        if package == nil {
            Logger.warning(Strings.paywall_could_not_find_package(component.packageID))
        }

        self.stackViewModel = stackViewModel
        self.hasPurchaseButton = hasPurchaseButton
        self.presentedOverrides = component.overrides?.toPresentedOverrides(discardRules: discardRules)
    }

    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue]
    ) -> Bool {
        let conditionContext = self.uiConfigProvider.conditionContext(
            selectedPackageId: selectedPackageId,
            customVariables: customVariables
        )

        let partial = PresentedPackagePartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            conditionContext: conditionContext,
            with: self.presentedOverrides
        )

        return partial?.visible ?? self.componentVisible ?? true
    }

}

extension PresentedPackagePartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialPackageComponent?,
        with other: PaywallComponent.PartialPackageComponent?
    ) -> Self {
        return .init(visible: other?.visible ?? base?.visible)
    }

}

#endif
