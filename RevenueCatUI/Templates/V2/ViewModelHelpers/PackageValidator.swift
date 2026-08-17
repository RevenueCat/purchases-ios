//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageValidator.swift
//
//  Created by Josh Holtz on 10/25/24.

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

/// The inputs default-package selection needs to resolve package visibility the same way the renderer
/// does. Eligibility is passed as lookups because it is resolved per package and lands asynchronously.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PackageSelectionContext {

    let condition: ScreenCondition
    let customVariables: [String: CustomVariableValue]
    let isEligibleForIntroOffer: (Package) -> Bool
    let isEligibleForPromoOffer: (Package) -> Bool

    init(
        condition: ScreenCondition,
        customVariables: [String: CustomVariableValue],
        isEligibleForIntroOffer: @escaping (Package) -> Bool,
        isEligibleForPromoOffer: @escaping (Package) -> Bool
    ) {
        self.condition = condition
        self.customVariables = customVariables
        self.isEligibleForIntroOffer = isEligibleForIntroOffer
        self.isEligibleForPromoOffer = isEligibleForPromoOffer
    }

    /// For the few places that must seed a selection before the render environment exists (view `init`).
    /// Rules keyed on custom variables or offer eligibility cannot be evaluated yet, so a selection made
    /// with this is provisional and has to be reconciled once the body resolves the real context.
    static var provisional: PackageSelectionContext {
        return .init(
            condition: .compact,
            customVariables: [:],
            isEligibleForIntroOffer: { _ in false },
            isEligibleForPromoOffer: { _ in false }
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageValidator {

    typealias PackageInfo = (
        package: Package,
        isSelectedByDefault: Bool,
        visibilityResolver: PackageVisibilityResolver,
        promotionalOfferProductCode: String?
    )

    private(set) var packageInfos: [PackageInfo] = []

    /// True when this validator has packages merged in from tabs. Selection is tab-local, so the
    /// page-level validator must not reconcile a selection across tab boundaries.
    private(set) var containsTabScopedPackages: Bool = false

    func add(_ packageInfo: PackageInfo) {
        self.packageInfos.append(packageInfo)
    }

    func addTabScoped(_ packageInfo: PackageInfo) {
        self.containsTabScopedPackages = true
        self.packageInfos.append(packageInfo)
    }

    var isValid: Bool {
        !packageInfos.isEmpty
    }

    var packages: [Package] {
        packageInfos.map(\.package)
    }

    private func visiblePackageInfos(in context: PackageSelectionContext) -> [PackageInfo] {
        return self.packageInfos.filter { info in
            info.visibilityResolver.visible(
                // Selection is what's being resolved, so nothing is selected yet. Pinning these two
                // inputs keeps resolution independent of its own output — otherwise a paywall with
                // `selected` or `selected_package` visibility rules could oscillate.
                state: .default,
                condition: context.condition,
                isEligibleForIntroOffer: context.isEligibleForIntroOffer(info.package),
                isEligibleForPromoOffer: context.isEligibleForPromoOffer(info.package),
                selectedPackageId: nil,
                customVariables: context.customVariables
            )
        }
    }

    /// The packages that actually render for the given context, in document order.
    func visiblePackages(in context: PackageSelectionContext) -> [Package] {
        return self.visiblePackageInfos(in: context).map(\.package)
    }

    /// Resolves which package should start selected.
    ///
    /// 1. the authored default (first `isSelectedByDefault` in document order), if it resolves visible
    /// 2. otherwise the first visible package in document order
    /// 3. otherwise `nil`
    func defaultSelectedPackage(in context: PackageSelectionContext) -> Package? {
        let visiblePackageInfos = self.visiblePackageInfos(in: context)

        if let defaultSelectedPackage = visiblePackageInfos.first(where: { $0.isSelectedByDefault }) {
            return defaultSelectedPackage.package
        }

        guard let fallback = visiblePackageInfos.first else {
            Logger.warning(Strings.paywall_could_not_find_any_packages)
            return nil
        }

        if let hiddenDefault = self.packageInfos.first(where: { $0.isSelectedByDefault }) {
            // The authored default resolved hidden, so nothing would appear selected. Falling back keeps
            // a package selected, but the paywall almost certainly isn't behaving as authored.
            Logger.warning(
                Strings.paywall_default_package_not_visible(
                    defaultPackage: hiddenDefault.package.identifier,
                    selectedPackage: fallback.package.identifier
                )
            )
        } else {
            Logger.warning(Strings.paywall_could_not_find_default_package)
        }

        return fallback.package
    }

    /// The selection that should be in effect for `context`, given whatever is currently selected.
    ///
    /// Returns `nil` when `current` is still visible, meaning nothing needs to change. Selection is only
    /// moved when the current package isn't rendering, which is why this can't discard a deliberate
    /// choice: the user can't have tapped a card that isn't on screen.
    func reconciledSelection(current: Package?, in context: PackageSelectionContext) -> Package? {
        let visiblePackageInfos = self.visiblePackageInfos(in: context)

        if let current, visiblePackageInfos.contains(where: { $0.package.identifier == current.identifier }) {
            return nil
        }

        return self.defaultSelectedPackage(in: context)
    }

}

#endif
