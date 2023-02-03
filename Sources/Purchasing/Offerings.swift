//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Offerings.swift
//
//  Created by Joshua Liebowitz on 7/12/21.
//

import Foundation

/**
 * This class contains all the offerings configured in RevenueCat dashboard.
 * Offerings let you control which products are shown to users without requiring an app update.
 *
 * Building paywalls that are dynamic and can react to different product
 * configurations gives you maximum flexibility to make remote updates.
 *
 * #### Related Articles
 * -  [Displaying Products](https://docs.revenuecat.com/docs/displaying-products)
 * - ``Offering``
 * - ``Package``
 */
@objc(RCOfferings) public final class Offerings: NSObject {

    /**
     Dictionary of all Offerings (``Offering``) objects keyed by their identifier. This dictionary can also be accessed
     by using an index subscript on ``Offerings``, e.g. `offerings["offering_id"]`. To access the current offering use
     ``Offerings/current``.
     */
    @objc public let all: [String: Offering]

    /**
     Current ``Offering`` configured in the RevenueCat dashboard.
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
     RevenueCat dashboard, e.g. `offerings.offering(identifier: "offering_id")` or `offerings[@"offering_id"]`.
     To access the current offering use ``Offerings/current``.
     */
    @objc public func offering(identifier: String?) -> Offering? {
        guard let identifier = identifier else {
            return nil
        }

        return all[identifier]
    }

    /// #### Related Symbols
    /// - ``offering(identifier:)``
    @objc public subscript(key: String) -> Offering? {
        return offering(identifier: key)
    }

    @objc public override var description: String {
        var description = "<Offerings {\n"
        for offering in all.values {
            description += "\t\(offering)\n"
        }
        description += "\tcurrentOffering=\(current?.description ?? "<none>")>"
        return description
    }

    init(offerings: [String: Offering], currentOfferingID: String?) {
        all = offerings
        self.currentOfferingID = currentOfferingID
    }

}

extension Offerings: Sendable {}
