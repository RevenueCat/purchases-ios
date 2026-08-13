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

    /// Where a package was declared. Selection inside a tab is tab-local, so a page-level resolution
    /// must never hand back a package that only exists in a tab.
    private enum Scope {
        case page
        case tab
    }

    private var scopedPackageInfos: [(info: PackageInfo, scope: Scope)] = []

    var packageInfos: [PackageInfo] {
        self.scopedPackageInfos.map(\.info)
    }

    private var hasPageScopedPackages: Bool {
        self.scopedPackageInfos.contains { $0.scope == .page }
    }

    private var pageScopedPackageInfos: [PackageInfo] {
        self.scopedPackageInfos.filter { $0.scope == .page }.map(\.info)
    }

    /// Warnings are emitted from resolution, which view bodies call on every render. Logging each
    /// distinct message once per validator keeps that out of the console.
    private var loggedWarnings: Set<String> = []

    func add(_ packageInfo: PackageInfo) {
        self.scopedPackageInfos.append((packageInfo, .page))
    }

    func addTabScoped(_ packageInfo: PackageInfo) {
        self.scopedPackageInfos.append((packageInfo, .tab))
    }

    var isValid: Bool {
        !self.scopedPackageInfos.isEmpty
    }

    var packages: [Package] {
        self.scopedPackageInfos.map(\.info.package)
    }

    private func isVisible(_ info: PackageInfo, in context: PackageSelectionContext) -> Bool {
        return info.visibilityResolver.visible(
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

    private func visiblePackageInfos(
        among packageInfos: [PackageInfo],
        in context: PackageSelectionContext
    ) -> [PackageInfo] {
        return packageInfos.filter { self.isVisible($0, in: context) }
    }

    /// The packages that actually render for the given context, in document order.
    func visiblePackages(in context: PackageSelectionContext) -> [Package] {
        return self.visiblePackageInfos(among: self.packageInfos, in: context).map(\.package)
    }

    /// Resolves which package should start selected.
    ///
    /// 1. the authored default (first `isSelectedByDefault` in document order), if it resolves visible
    /// 2. otherwise the first visible package in document order
    /// 3. otherwise `nil`
    func defaultSelectedPackage(in context: PackageSelectionContext) -> Package? {
        return self.defaultSelectedPackage(among: self.packageInfos, in: context)
    }

    /// The selection that should be in effect for `context`, or `nil` when nothing needs to change.
    ///
    /// Only moves a selection nothing is rendering, so it can't discard a tap, and only to a package
    /// declared outside the tabs, since a page selection can't point into a tab the user isn't on.
    func reconciledSelection(current: Package?, in context: PackageSelectionContext) -> Package? {
        guard self.hasPageScopedPackages else {
            // Every package lives in a tab, and each tab reconciles its own selection.
            return nil
        }

        if let current, self.isRendering(current, in: context) {
            return nil
        }

        return self.defaultSelectedPackage(among: self.pageScopedPackageInfos, in: context)
    }

    /// Whether a card for `package` is on screen.
    ///
    /// Where the page declares the package, only those occurrences count: a page card a rule hides isn't
    /// on screen just because some tab repeats the same identifier. Packages the page doesn't declare are
    /// left to the tabs, which is as close to "the active tab renders it" as this can get.
    private func isRendering(_ package: Package, in context: PackageSelectionContext) -> Bool {
        let occurrences = self.scopedPackageInfos.filter { $0.info.package.identifier == package.identifier }
        let pageOccurrences = occurrences.filter { $0.scope == .page }
        let deciding = pageOccurrences.isEmpty ? occurrences : pageOccurrences

        return deciding.contains { self.isVisible($0.info, in: context) }
    }

    private func defaultSelectedPackage(
        among packageInfos: [PackageInfo],
        in context: PackageSelectionContext
    ) -> Package? {
        let visiblePackageInfos = self.visiblePackageInfos(among: packageInfos, in: context)

        if let defaultSelectedPackage = visiblePackageInfos.first(where: { $0.isSelectedByDefault }) {
            return defaultSelectedPackage.package
        }

        guard let fallback = visiblePackageInfos.first else {
            self.warnOnce(Strings.paywall_could_not_find_any_packages)
            return nil
        }

        if let hiddenDefault = packageInfos.first(where: { $0.isSelectedByDefault }) {
            // The authored default resolved hidden, so nothing would appear selected. Falling back keeps
            // a package selected, but the paywall almost certainly isn't behaving as authored.
            self.warnOnce(
                Strings.paywall_default_package_not_visible(
                    defaultPackage: hiddenDefault.package.identifier,
                    selectedPackage: fallback.package.identifier
                )
            )
        } else {
            self.warnOnce(Strings.paywall_could_not_find_default_package)
        }

        return fallback.package
    }

    private func warnOnce(_ warning: Strings) {
        guard self.loggedWarnings.insert(warning.description).inserted else {
            return
        }

        Logger.warning(warning)
    }

}

#endif
