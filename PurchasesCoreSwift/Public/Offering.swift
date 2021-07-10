//
//  Offering.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

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
     Array of `RCPackage` objects available for purchase.
     */
    @objc public let availablePackages: [Package]

    /**
     Lifetime package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var lifetime: Package?

    /**
     Annual package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var annual: Package?

    /**
     Six month package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var sixMonth: Package?

    /**
     Three month package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var threeMonth: Package?

    /**
     Two month package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var twoMonth: Package?

    /**
     Monthly package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var monthly: Package?

    /**
     Weekly package type configured in the RevenueCat dashboard, if available.
     */
    @objc private(set) public var weekly: Package?

    // TODO(post-migration): Change back to internal instead of public
    @objc public init(identifier: String, serverDescription: String, availablePackages: [Package]) {
        self.identifier = identifier
        self.serverDescription = serverDescription
        self.availablePackages = availablePackages

        // TODO: add validation to ensure we don't get multiple packages with the same type
        for package in availablePackages {
            switch package.packageType {
            case .lifetime:
                self.lifetime = package
            case .annual:
                self.annual = package
            case .sixMonth:
                self.sixMonth = package
            case .threeMonth:
                self.threeMonth = package
            case .twoMonth:
                self.twoMonth = package
            case .monthly:
                self.monthly = package
            case .weekly:
                self.weekly = package
            case .unknown, .custom:
                break
            }
        }
    }

    public override var description: String {
        return """
        <Offering {\n\tidentifier=\(identifier)\n\tserverDescription=\(serverDescription)\n"
        \tavailablePackages=\(valueOrEmpty(availablePackages))\n\tlifetime=\(valueOrEmpty(lifetime))\n
        \tannual=\(valueOrEmpty(annual))\n\tsixMonth=\(valueOrEmpty(sixMonth))\n
        \tthreeMonth=\(valueOrEmpty(threeMonth))\n\ttwoMonth=\(valueOrEmpty(twoMonth))\n
        \tmonthly=\(valueOrEmpty(monthly))\n\tweekly=\(valueOrEmpty(weekly))\n}>
        """
    }

    private func valueOrEmpty<T: CustomStringConvertible>(_ value: T?) -> String {
        if let value = value {
            return value.description
        } else {
            return ""
        }
    }

    /**
     Retrieves a specific package by identifier, use this to access custom package types configured in the RevenueCat dashboard, e.g. `[offering packageWithIdentifier:@"custom_package_id"]` or `offering[@"custom_package_id"]`.
     */
    @objc public func package(identifier: String?) -> Package? {
        guard let identifier = identifier else {
            return nil
        }

        return availablePackages
            .filter { $0.identifier == identifier }
            .first
    }

    /// :nodoc:
    @objc public func object(forKeyedSubscript key: String) -> Package? {
        return package(identifier: key)
    }

}
