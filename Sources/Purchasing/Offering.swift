//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Offering.swift
//
//  Created by Joshua Liebowitz on 7/9/21.
//

import Foundation

/**
 * An offering is a collection of ``Package``s, and they let you control which products
 * are shown to users without requiring an app update.
 *
 * Building paywalls that are dynamic and can react to different product
 * configurations gives you maximum flexibility to make remote updates.
 *
 * #### Related Articles
 * -  [Displaying Products](https://docs.revenuecat.com/docs/displaying-products)
 * - ``Offerings``
 * - ``Package``
 */
@objc(RCOffering) public final class Offering: NSObject {

    /**
     Unique identifier defined in RevenueCat dashboard.
     */
    @objc public let identifier: String

    /**
     Offering description defined in RevenueCat dashboard.
     */
    @objc public let serverDescription: String

    /**
     Array of ``Package`` objects available for purchase.
     */
    @objc public let availablePackages: [Package]

    /**
     Lifetime ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let lifetime: Package?

    /**
     Annual ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let annual: Package?

    /**
     Six month ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let sixMonth: Package?

    /**
     Three month ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let threeMonth: Package?

    /**
     Two month ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let twoMonth: Package?

    /**
     Monthly ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let monthly: Package?

    /**
     Weekly ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc public let weekly: Package?

    public override var description: String {
        return """
        <Offering {\n\tidentifier=\(identifier)\n\tserverDescription=\(serverDescription)\n"
        \tavailablePackages=\(valueOrEmpty(availablePackages))\n\tlifetime=\(valueOrEmpty(lifetime))\n
        \tannual=\(valueOrEmpty(annual))\n\tsixMonth=\(valueOrEmpty(sixMonth))\n
        \tthreeMonth=\(valueOrEmpty(threeMonth))\n\ttwoMonth=\(valueOrEmpty(twoMonth))\n
        \tmonthly=\(valueOrEmpty(monthly))\n\tweekly=\(valueOrEmpty(weekly))\n}>
        """
    }

    /**
     Retrieves a specific ``Package`` by identifier, use this to access custom package types configured in the 
     RevenueCat dashboard, e.g. `offering.package(identifier: "custom_package_id")` or
     `offering["custom_package_id"]`.
     */
    @objc public func package(identifier: String?) -> Package? {
        guard let identifier = identifier else {
            return nil
        }

        return availablePackages
            .filter { $0.identifier == identifier }
            .first
    }

    /// #### Related Symbols
    /// - ``package(identifier:)``
    @objc public subscript(key: String) -> Package? {
        return package(identifier: key)
    }

    // swiftlint:disable:next cyclomatic_complexity
    init(identifier: String, serverDescription: String, availablePackages: [Package]) {
        self.identifier = identifier
        self.serverDescription = serverDescription
        self.availablePackages = availablePackages

        var foundPackages: [PackageType: Package] = [:]

        var lifetime: Package?
        var annual: Package?
        var sixMonth: Package?
        var threeMonth: Package?
        var twoMonth: Package?
        var monthly: Package?
        var weekly: Package?

        for package in availablePackages {
            Self.checkForNilAndLogReplacement(previousPackages: foundPackages, newPackage: package)

            switch package.packageType {
            case .lifetime: lifetime = package
            case .annual: annual = package
            case .sixMonth: sixMonth = package
            case .threeMonth: threeMonth = package
            case .twoMonth: twoMonth = package
            case .monthly: monthly = package
            case .weekly: weekly = package
            case .custom where package.storeProduct.productCategory == .nonSubscription:
                // Non-subscription product, ignoring
                continue

            case .custom:
                Logger.debug(Strings.offering.custom_package_type(package))
                continue

            case .unknown:
                Logger.warn(Strings.offering.unknown_package_type(package))
                continue
            }

            foundPackages[package.packageType] = package
        }

        self.lifetime = lifetime
        self.annual = annual
        self.sixMonth = sixMonth
        self.threeMonth = threeMonth
        self.twoMonth = twoMonth
        self.monthly = monthly
        self.weekly = weekly

        super.init()
    }

}

extension Offering: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: String { return self.identifier }

}

extension Offering: Sendable {}

// MARK: - Private

private extension Offering {

    static func checkForNilAndLogReplacement(previousPackages: [PackageType: Package], newPackage: Package) {
        if let package = previousPackages[newPackage.packageType] {
            Logger.warn("Package: \(package.identifier) already exists, overwriting with: \(newPackage.identifier)")
        }
    }

}

private func valueOrEmpty<T: CustomStringConvertible>(_ value: T?) -> String {
    return value?.description ?? ""
}
