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
    ///   - presentedOverrides: Override configurations to apply
    /// - Returns: Configured partial component
    // swiftlint:disable:next function_parameter_count
    static func buildPartial(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
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
            case .introOffer:
                if !isEligibleForIntroOffer {
                    return false
                }
            case .promoOffer:
                if !isEligibleForPromoOffer {
                    return false
                }
            case .selected:
                if state != .selected {
                    return false
                }
            case .unsupported:
                return false
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
