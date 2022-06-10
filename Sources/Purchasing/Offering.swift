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
@objc(RCOffering) public class Offering: NSObject {

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
    @objc private(set) public var lifetime: Package?

    /**
     Annual ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var annual: Package?

    /**
     Six month ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var sixMonth: Package?

    /**
     Three month ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var threeMonth: Package?

    /**
     Two month ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var twoMonth: Package?

    /**
     Monthly ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var monthly: Package?

    /**
     Weekly ``Package`` type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var weekly: Package?

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

    init(identifier: String, serverDescription: String, availablePackages: [Package]) {
        self.identifier = identifier
        self.serverDescription = serverDescription
        self.availablePackages = availablePackages

        for package in availablePackages {
            switch package.packageType {
            case .lifetime:
                Self.checkForNilAndLogReplacement(package: self.lifetime, newPackage: package)
                self.lifetime = package
            case .annual:
                Self.checkForNilAndLogReplacement(package: self.annual, newPackage: package)
                self.annual = package
            case .sixMonth:
                Self.checkForNilAndLogReplacement(package: self.sixMonth, newPackage: package)
                self.sixMonth = package
            case .threeMonth:
                Self.checkForNilAndLogReplacement(package: self.threeMonth, newPackage: package)
                self.threeMonth = package
            case .twoMonth:
                Self.checkForNilAndLogReplacement(package: self.twoMonth, newPackage: package)
                self.twoMonth = package
            case .monthly:
                Self.checkForNilAndLogReplacement(package: self.monthly, newPackage: package)
                self.monthly = package
            case .weekly:
                Self.checkForNilAndLogReplacement(package: self.weekly, newPackage: package)
                self.weekly = package
            case .custom where package.storeProduct.productCategory == .nonSubscription:
                // Non-subscription product, ignoring
                break
            case .unknown, .custom:
                Logger.warn(
                    "Unknown subscription length for package '\(package.offeringIdentifier)': " +
                    "\(package.packageType). Ignoring."
                )
            }
        }
    }

    private static func checkForNilAndLogReplacement(package: Package?, newPackage: Package) {
        guard let package = package else {
            return
        }

        Logger.warn("Package: \(package.identifier) already exists, overwriting with:\(newPackage.identifier)")
    }

    private func valueOrEmpty<T: CustomStringConvertible>(_ value: T?) -> String {
        if let value = value {
            return value.description
        } else {
            return ""
        }
    }

}

extension Offering: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: String { return self.identifier }

}
