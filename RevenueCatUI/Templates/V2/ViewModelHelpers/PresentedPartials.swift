//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizedPartials.swift
//
//  Created by Josh Holtz on 10/27/24.
//

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

/// Protocol defining how partial components can be combined
protocol PresentedPartial {

    /// Combines two partial components, allowing for override behavior
    /// - Parameters:
    ///   - base: The base partial component
    ///   - other: The overriding partial component
    /// - Returns: Combined partial component
    static func combine(_ base: Self?, with other: Self?) -> Self

}

/// Array holding override configurations for different presentation states
typealias PresentedOverrides<T: PresentedPartial> = [PresentedOverride<T>]

/// Structure holding override configurations for a presentation state
struct PresentedOverride<T: PresentedPartial> {

    let conditions: [PaywallComponent.Condition]
    let properties: T?

}

extension PresentedPartial {

    /// Builds a partial component based on current state and conditions
    /// - Parameters:
    ///   - state: Current view state (selected/unselected)
    ///   - condition: Current screen condition (compact/medium/expanded)
    ///   - isEligibleForIntroOffer: Whether the selected package is intro-eligible.
    ///   - isEligibleForPromoOffer: Whether the selected package is promo-eligible.
    ///   - anyPackageHasIntroOffer: Whether any package in the context exposes an intro offer.
    ///   - anyPackageHasPromoOffer: Whether any package in the context exposes a promo offer.
    ///   - appVersionInt: The app version as an integer (dots removed from version string).
    ///   - presentedOverrides: Override configurations to apply
    /// - Returns: Configured partial component
    // swiftlint:disable:next function_parameter_count
    static func buildPartial(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        anyPackageHasIntroOffer: Bool = false,
        anyPackageHasPromoOffer: Bool = false,
        appVersionInt: Int = SystemInfo.appVersion.extractNumber() ?? 0,
        selectedPackage: Package?,
        with presentedOverrides: PresentedOverrides<Self>?
    ) -> Self? {
        guard let presentedOverrides else {
            return nil
        }

        var presentedPartial: Self?

        for presentedOverride in presentedOverrides where self.shouldApply(
            for: presentedOverride.conditions,
            state: state,
            activeCondition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            anyPackageHasIntroOffer: anyPackageHasIntroOffer,
            anyPackageHasPromoOffer: anyPackageHasPromoOffer,
            appVersionInt: appVersionInt,
            selectedPackage: selectedPackage
        ) {
            presentedPartial = Self.combine(presentedPartial, with: presentedOverride.properties)
        }

        return presentedPartial
    }

    // swiftlint:disable:next cyclomatic_complexity function_parameter_count
    private static func shouldApply(
        for conditions: [PaywallComponent.Condition],
        state: ComponentViewState,
        activeCondition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        anyPackageHasIntroOffer: Bool,
        anyPackageHasPromoOffer: Bool,
        appVersionInt: Int,
        selectedPackage: Package?
    ) -> Bool {
        // Early return when any condition evaluates to false
        for condition in conditions {
            switch condition {
            case .orientation(let operand, let orientations):
                let active = activeCondition.orientation.rawValue

                switch operand {
                case .in:
                    return orientations.contains(where: { $0.rawValue == active })
                case .notIn:
                    return !orientations.contains(where: { $0.rawValue == active })
                @unknown default:
                    return false
                }
            case .screenSize(let operand, let sizes):
                guard let active = activeCondition.screenSize?.name else {
                    return false
                }

                switch operand {
                case .in:
                    return sizes.contains(where: { $0 == active })
                case .notIn:
                    return !sizes.contains(where: { $0 == active })
                @unknown default:
                    return false
                }
            case let .selectedPackage(operand, packages):
                if let selectedPackage = selectedPackage {
                    switch operand {
                    case .in:
                        return packages.contains(where: { $0 == selectedPackage.identifier })
                    case .notIn:
                        return !packages.contains(where: { $0 == selectedPackage.identifier })
                    @unknown default:
                        return false
                    }
                }
                return false
            case .introOffer(let operand, let value):
                switch operand {
                case .equals:
                    return isEligibleForIntroOffer == value
                case .notEquals:
                    return isEligibleForIntroOffer != value
                @unknown default:
                    return false
                }
            case .anyPackageContainsIntroOffer(let operand, let value):
                switch operand {
                case .equals:
                    return anyPackageHasIntroOffer == value
                case .notEquals:
                    return anyPackageHasIntroOffer != value
                @unknown default:
                    return false
                }
            case .promoOffer(let operand, let value):
                switch operand {
                case .equals:
                    return isEligibleForPromoOffer == value
                case .notEquals:
                    return isEligibleForPromoOffer != value
                @unknown default:
                    return false
                }
            case .anyPackageContainsPromoOffer(let operand, let value):
                switch operand {
                case .equals:
                    return anyPackageHasPromoOffer == value
                case .notEquals:
                    return anyPackageHasPromoOffer != value
                @unknown default:
                    return false
                }
            case .selected:
                if state != .selected {
                    return false
                }
            case .appVersion(let operand, let value):
                switch operand {
                case .lessThan:
                    if !(appVersionInt < value) {
                        return false
                    }
                case .lessThanOrEqual:
                    if !(appVersionInt <= value) {
                        return false
                    }
                case .equal:
                    if !(appVersionInt == value) {
                        return false
                    }
                case .greaterThan:
                    if !(appVersionInt > value) {
                        return false
                    }
                case .greaterThanOrEqual:
                    if !(appVersionInt >= value) {
                        return false
                    }
                @unknown default:
                    return false
                }
            case .unsupported:
                return true // ignore unsupported case and show partial
            @unknown default:
                return false
            }
        }

        return true
    }

}

extension Array {

    /// Converts component overrides to presented overrides
    /// - Parameter convert: Conversion function to apply
    /// - Returns: Presented overrides with converted components
    func toPresentedOverrides<
        T: PaywallPartialComponent,
        P: PresentedPartial
    >(
        convert: (T) throws -> P
    ) rethrows -> PresentedOverrides<P>
    where Element == PaywallComponent.ComponentOverride<T> {
        return try self.compactMap { partial in
            let presentedPartial = try convert(partial.properties)

            return PresentedOverride(
                conditions: partial.conditions,
                properties: presentedPartial
            )
        }
    }

}

#endif
