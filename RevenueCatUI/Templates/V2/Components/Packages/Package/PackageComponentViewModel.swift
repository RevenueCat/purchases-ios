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

    /// Resolved once like ButtonComponentViewModel does: looking up the localized bundle
    /// repeatedly would repeat a path search on every render.
    private let localizedBundle: Bundle

    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel,
        hasPurchaseButton: Bool,
        uiConfigProvider: UIConfigProvider,
        locale: Locale = .current,
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
        self.localizedBundle = Localization.localizedBundle(locale)
    }

    /// Whether a text inside this package announces the selection state itself. When it does,
    /// the row must not also expose the state as an accessibility value, or it is said twice.
    private(set) var announcesSelectionInText = false

    /// Marks the package's first text so it speaks the selection state right after the offer's
    /// name. Descends stacks only: a nested button or purchase button carries its own label
    /// ("Continue"), which is not this offer's name.
    func markFirstTextForSelectionAnnouncement() {
        guard let text = Self.firstText(in: self.stackViewModel) else {
            return
        }

        text.announcesPackageSelection = true
        self.announcesSelectionInText = true
    }

    private static func firstText(in stack: StackComponentViewModel) -> TextComponentViewModel? {
        for viewModel in stack.viewModels {
            switch viewModel {
            case .text(let text):
                // A hidden or empty text renders nothing, so it cannot speak the state. Passing
                // over it keeps looking, and leaves the row-level value fallback in play when
                // the card turns out to have no announceable text at all.
                guard text.announcesText else {
                    continue
                }

                return text
            case .stack(let nested):
                if let found = Self.firstText(in: nested) {
                    return found
                }
            default:
                continue
            }
        }

        return nil
    }

    /// Spoken selection state for the package row, so a screen reader user can tell which
    /// offer is active ("Yearly, Selected" vs "Monthly, Not selected").
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
        customVariables: [String: CustomVariableValue]
    ) -> Bool {
        return self.visibilityResolver.visible(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackageId: selectedPackageId,
            customVariables: customVariables
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
