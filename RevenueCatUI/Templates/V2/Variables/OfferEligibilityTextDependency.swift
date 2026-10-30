//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferEligibilityTextDependency.swift
//

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

/// Offers that can affect each product on this screen. This only narrows loading; it does not
/// replace the eligibility results used to render or purchase an offer.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct OfferEligibilityAvailability {

    /// Standalone component previews have no paywall configuration. Keep their loading overrides intact.
    static let unknown = Self(offersByProductID: nil)

    private let offersByProductID: [String: OfferEligibilityLoading]?

    init(packageInfos: [(package: Package, promotionalOfferProductCode: String?)]) {
        var offersByProductID: [String: OfferEligibilityLoading] = [:]
        for info in packageInfos {
            let product = info.package.storeProduct
            var offers: OfferEligibilityLoading = []
            if product.introductoryDiscount != nil {
                offers.insert(.intro)
            }
            if let code = info.promotionalOfferProductCode,
               product.discounts.contains(where: { $0.offerIdentifier == code }) {
                offers.insert(.promo)
            }
            offersByProductID[product.id, default: []].formUnion(offers)
        }
        self.init(offersByProductID: offersByProductID)
    }

    private init(offersByProductID: [String: OfferEligibilityLoading]?) {
        self.offersByProductID = offersByProductID
    }

    func loading(_ loading: OfferEligibilityLoading, for package: Package?) -> OfferEligibilityLoading {
        guard let offersByProductID = self.offersByProductID else {
            return loading
        }
        guard let package else { return [] }
        return loading.intersection(offersByProductID[package.storeProduct.id] ?? [])
    }

    /// Container visibility and selection use `isMostLikelyEligible`, whose subscription-history
    /// fallback can change even without a configured promo. Only signed-offer text can narrow that wait.
    func loadingForVisibility(_ loading: OfferEligibilityLoading, for package: Package?) -> OfferEligibilityLoading {
        return self.loading(loading, for: package).union(loading.intersection(.promo))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct OfferEligibilityState {

    let isEligibleForIntroOffer: Bool
    let isEligibleForPromoOffer: Bool
    let loading: OfferEligibilityLoading

    var isLoading: Bool {
        return !self.loading.isEmpty
    }

    /// Eligibility values still in play. A resolved check contributes only its result, so a component
    /// that depends on the other check can render as soon as its own check finishes.
    func unresolvedOutcomes(
        variesWithEligibility: Bool
    ) -> [(isEligibleForIntroOffer: Bool, isEligibleForPromoOffer: Bool)] {
        let introValues = variesWithEligibility && self.loading.contains(.intro)
            ? [false, true]
            : [self.isEligibleForIntroOffer]
        let promoValues = variesWithEligibility && self.loading.contains(.promo)
            ? [false, true]
            : [self.isEligibleForPromoOffer]

        return introValues.flatMap { isEligibleForIntroOffer in
            promoValues.map { isEligibleForPromoOffer in
                (
                    isEligibleForIntroOffer: isEligibleForIntroOffer,
                    isEligibleForPromoOffer: isEligibleForPromoOffer
                )
            }
        }
    }

    /// Whether the eligibility results still in play disagree about visibility.
    func visibilityCanChange(
        variesWithEligibility: Bool,
        isVisible: (_ isEligibleForIntroOffer: Bool, _ isEligibleForPromoOffer: Bool) -> Bool
    ) -> Bool {
        guard self.isLoading, variesWithEligibility else {
            return false
        }

        var couldBeVisible = false
        var couldBeHidden = false
        for outcome in self.unresolvedOutcomes(variesWithEligibility: variesWithEligibility) {
            if isVisible(outcome.isEligibleForIntroOffer, outcome.isEligibleForPromoOffer) {
                couldBeVisible = true
            } else {
                couldBeHidden = true
            }
        }

        return couldBeVisible && couldBeHidden
    }

}

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OfferEligibilityAvailabilityKey: EnvironmentKey {

    static let defaultValue = OfferEligibilityAvailability.unknown

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var offerEligibilityAvailability: OfferEligibilityAvailability {
        get { self[OfferEligibilityAvailabilityKey.self] }
        set { self[OfferEligibilityAvailabilityKey.self] = newValue }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol OfferEligibilityVisibilityDependency {

    var dependsOnOfferEligibility: Bool { get }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PresentedOverride {

    var dependsOnOfferEligibility: Bool {
        return self.conditions.contains(where: \.dependsOnOfferEligibility)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OfferEligibilityRedactionModifier: ViewModifier {

    @Environment(\.offerEligibilityLoading)
    private var offerEligibilityLoading

    @Environment(\.offerEligibilityAvailability)
    private var offerEligibilityAvailability

    @EnvironmentObject
    private var packageContext: PackageContext

    let dependsOnOfferEligibility: Bool
    let isEligibleForIntroOffer: Bool
    let isEligibleForPromoOffer: Bool
    let isVisible: (_ isEligibleForIntroOffer: Bool, _ isEligibleForPromoOffer: Bool) -> Bool

    func body(content: Content) -> some View {
        let offerEligibility = OfferEligibilityState(
            isEligibleForIntroOffer: self.isEligibleForIntroOffer,
            isEligibleForPromoOffer: self.isEligibleForPromoOffer,
            loading: self.offerEligibilityAvailability.loadingForVisibility(
                self.offerEligibilityLoading,
                for: self.packageContext.package
            )
        )
        let redacts = offerEligibility.visibilityCanChange(
            variesWithEligibility: self.dependsOnOfferEligibility,
            isVisible: self.isVisible
        )

        content.redacted(reason: redacts ? .placeholder : [])
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func redactedWhileOfferEligibilityLoads<Dependency: OfferEligibilityVisibilityDependency>(
        _ dependency: Dependency,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        isVisible: @escaping (_ isEligibleForIntroOffer: Bool, _ isEligibleForPromoOffer: Bool) -> Bool
    ) -> some View {
        return self.modifier(OfferEligibilityRedactionModifier(
            dependsOnOfferEligibility: dependency.dependsOnOfferEligibility,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            isVisible: isVisible
        ))
    }

}

#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.ExtendedCondition {

    /// Intro and promo checks are the only conditions whose result arrives after first render.
    /// `multipleIntroOffers` is always false on iOS, so it does not vary while a check is in flight.
    var dependsOnOfferEligibility: Bool {
        switch self {
        case .introOffer, .promoOffer, .introOfferCondition, .promoOfferCondition:
            return true
        case .compact, .medium, .expanded, .selected, .multipleIntroOffers, .variable,
             .selectedPackage, .state, .windowWidth, .windowHeight, .windowAspectRatio, .unsupported:
            return false
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariablesV2 {

    /// Substitution reads the discount selected from intro and promo eligibility.
    ///
    /// Every `product.offer_*` case is included. A variable that reads `OfferContext` under another
    /// name has to be added here. `OfferEligibilityTextRedactionTests` pins the resulting set.
    var dependsOnOfferEligibility: Bool {
        switch self {
        case .productRelativeDiscountWithOffer,
             .productAbsoluteDiscountWithOffer,
             .productRelativeDiscountWithOfferFullPeriod,
             .productAbsoluteDiscountWithOfferFullPeriod:
            return true
        default:
            return self.rawValue.hasPrefix("product.offer_")
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariableHandlerV2 {

    /// Whether `text` contains a variable whose value is chosen from intro or promo eligibility.
    static func textDependsOnOfferEligibility(
        _ text: String,
        variableCompatibilityMap: [String: String]
    ) -> Bool {
        return Whisker.variableNames(in: text).contains { variableName in
            self.resolvedVariable(
                variableName,
                variableCompatibilityMap: variableCompatibilityMap
            )?.dependsOnOfferEligibility == true
        }
    }

    /// Same name resolution as `findVariable`, without logging unrecognized names.
    private static func resolvedVariable(
        _ variableRaw: String,
        variableCompatibilityMap: [String: String]
    ) -> VariablesV2? {
        if let variable = VariablesV2(rawValue: variableRaw) {
            return variable
        }

        guard let mappedName = variableCompatibilityMap[variableRaw] else {
            return nil
        }

        return VariablesV2(rawValue: mappedName)
    }

}
