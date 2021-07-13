//
//  Offerings.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 7/12/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

/**
 This class contains all the offerings configured in RevenueCat dashboard.
 For more info see https://docs.revenuecat.com/docs/entitlements
 */
@objc(RCOfferings) public class Offerings: NSObject {

    /**
     Dictionary of all Offerings (`RCOffering`) objects keyed by their identifier. This dictionary can also be accessed
     by using an index subscript on RCOfferings, e.g. `offerings[@"offering_id"]`. To access the current offering use
     `RCOfferings.current`.
     */
    @objc public let all: [String: Offering]

    /**
     Current offering configured in the RevenueCat dashboard.
     */
    @objc public var current: Offering? {
        guard let currentOfferingID = currentOfferingID else {
            return nil
        }
        return all[currentOfferingID]
    }

    private let currentOfferingID: String?

    /**
     Retrieves a specific offering by its identifier, use this to access additional offerings configured in the
     RevenueCat dashboard, e.g. `[offerings offeringWithIdentifier:@"offering_id"]` or `offerings[@"offering_id"]`.
     To access the current offering use `RCOfferings.current`.
     */
    @objc public func offering(identifier: String?) -> Offering? {
        guard let identifier = identifier else {
            return nil
        }

        return all[identifier]
    }

    /// :nodoc:
    @objc public subscript(key: String) -> Offering? {
        return offering(identifier: key)
    }

    // TODO (Post-migration): Remove @objc and make it internal again.
    // TODO: currentOfferingID probably shouldn't be optional, but 1 of our tests fail if it is.
    @objc public init(offerings: [String: Offering], currentOfferingID: String?) {
        all = offerings
        self.currentOfferingID = currentOfferingID
    }

    @objc public override var description: String {
        var description = "<Offerings {\n"
        for offering in all.values {
            description += "\t\(offering)\n"
        }
        description += "\tcurrentOffering=\(current?.description ?? "<none>")>"
        return description
    }

}
