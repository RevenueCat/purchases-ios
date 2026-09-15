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
    let hapticFeedbackEnabled: Bool

    let visibilityResolver: PackageVisibilityResolver

    /// Resolved once: the bundle lookup repeats a path search on every render.
    private let localizedBundle: Bundle

    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel,
        hasPurchaseButton: Bool,
        uiConfigProvider: UIConfigProvider,
        localizationProvider: LocalizationProvider,
        discardRules: Bool = false
    ) {
        self.visibilityResolver = PackageVisibilityResolver(
            component: component,
            uiConfigProvider: uiConfigProvider,
            discardRules: discardRules
        )
        self.isSelectedByDefault = component.isSelectedByDefault
        self.promotionalOfferProductCode = component.applePromoOfferProductCode
        self.componentName = component.name
        self.hapticFeedbackEnabled = component.hapticFeedbackEnabled ?? true

        self.package = offering.package(identifier: component.packageID)
        if package == nil {
            Logger.warning(Strings.paywall_could_not_find_package(component.packageID))
        }

        self.stackViewModel = stackViewModel
        self.hasPurchaseButton = hasPurchaseButton
        self.localizedBundle = Localization.localizedBundle(localizationProvider.locale)
    }

    /// Spoken selection state for the row: "Yearly, Selected" vs "Monthly, Not selected".
    func accessibilitySelectionValue(isSelected: Bool) -> String {
        return self.localizedBundle.localizedString(
            forKey: isSelected ? "Selected" : "Not selected",
            value: nil,
            table: nil
        )
    }

    // swiftlint:disable:next function_parameter_count
    func visible(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        selectedPackageId: String?,
        customVariables: [String: CustomVariableValue],
        windowSize: CGSize? = nil
    ) -> Bool {
        return self.visibilityResolver.visible(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackageId: selectedPackageId,
            customVariables: customVariables,
            windowSize: windowSize
        )
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
