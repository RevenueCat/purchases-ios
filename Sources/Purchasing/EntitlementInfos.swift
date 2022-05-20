//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementInfos.swift
//
//  Created by Joshua Liebowitz on 6/28/21.
//

import Foundation

/**
 This class contains all the entitlements associated to the user.
 */
@objc(RCEntitlementInfos) public class EntitlementInfos: NSObject {
    /**
     Dictionary of all EntitlementInfo (``EntitlementInfo``) objects (active and inactive) keyed by entitlement
     identifier. This dictionary can also be accessed by using an index subscript on ``EntitlementInfos``, e.g.
     `entitlementInfos["pro_entitlement_id"]`.
     */
    @objc public let all: [String: EntitlementInfo]

    /**
     Dictionary of active ``EntitlementInfo`` (`RCEntitlementInfo`) objects keyed by entitlement identifier.
     */
    @objc public var active: [String: EntitlementInfo] {
        return self.all.filter { $0.value.isActive }
    }

    /// #### Related Symbols
    /// `- `all``
    @objc public subscript(key: String) -> EntitlementInfo? {
        return self.all[key]
    }

    public override var description: String {
        return "<\(NSStringFromClass(Self.self)): self.all=\(self.all), self.active=\(self.active)>"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? EntitlementInfos else {
            return false
        }

        return self.isEqual(to: other)
    }

    init(entitlements: [String: EntitlementInfo]) {
        self.all = entitlements
    }

    private func isEqual(to other: EntitlementInfos?) -> Bool {
        guard let other = other else {
            return false
        }

        if self === other {
            return true
        }

        return self.all == other.all
    }

}

extension EntitlementInfos {

    convenience init(
        entitlements: [String: CustomerInfoResponse.Entitlement],
        purchases: [String: CustomerInfoResponse.Subscription],
        requestDate: Date?
    ) {
        self.init(
            entitlements: Dictionary(
                uniqueKeysWithValues: entitlements.compactMap { identifier, entitlement in
                    guard let subscription = purchases[entitlement.productIdentifier] else {
                        return nil
                    }

                    return (
                        identifier,
                        EntitlementInfo(identifier: identifier,
                                        entitlement: entitlement,
                                        subscription: subscription,
                                        requestDate: requestDate)
                    )
                }
            )
        )
    }

}
