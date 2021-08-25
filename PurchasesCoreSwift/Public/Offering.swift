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

    init(identifier: String, serverDescription: String, availablePackages: [Package]) {
        self.identifier = identifier
        self.serverDescription = serverDescription
        self.availablePackages = availablePackages

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

    /**
     Retrieves a specific package by identifier, use this to access custom package types configured in the RevenueCat
     dashboard, e.g. `[offering packageWithIdentifier:@"custom_package_id"]` or `offering[@"custom_package_id"]`.
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
    @objc public subscript(key: String) -> Package? {
        return package(identifier: key)
    }

    private func valueOrEmpty<T: CustomStringConvertible>(_ value: T?) -> String {
        if let value = value {
            return value.description
        } else {
            return ""
        }
    }

}
