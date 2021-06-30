//
//  EntitlementInfos.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

/**
 This class contains all the entitlements associated to the user.
 */
@objc(RCEntitlementInfos) public class EntitlementInfos: NSObject {
    /**
     Dictionary of all EntitlementInfo (`RCEntitlementInfo`) objects (active and inactive) keyed by entitlement
     identifier. This dictionary can also be accessed by using an index subscript on EntitlementInfos, e.g.
     `entitlementInfos[@"pro_entitlement_id"]`.
     */
    @objc public let all: [String: EntitlementInfo]

    /**
     Dictionary of active EntitlementInfo (`RCEntitlementInfo`) objects keyed by entitlement identifier.
     */
    @objc public var active: [String: EntitlementInfo] {
        return self.all.filter { $0.value.isActive }
    }

    @objc public init(entitlementsData: [String: Any]?,
                      purchasesData: [String: Any],
                      dateFormatter: DateFormatter,
                      requestDate: Date?) {
        guard let entitlementsData = entitlementsData else {
            self.all = [:]
            return
        }

        var entitlementInfos: [String: EntitlementInfo] = [:]
        entitlementsData.forEach { identifier, entitlement in
            guard let entitlement = entitlement as? [String: Any] else {
                return
            }

            guard let productIdentifier = entitlement["product_identifier"] as? String else {
                return
            }

            let productData = purchasesData[productIdentifier]
            guard let productData = productData as? [String: Any] else {
                return
            }
            entitlementInfos[identifier] = EntitlementInfo(entitlementId: identifier,
                                                           entitlementData: entitlement,
                                                           productData: productData,
                                                           dateFormatter: dateFormatter,
                                                           requestDate: requestDate)
        }
        self.all = entitlementInfos
    }

    @objc public subscript(key: String) -> EntitlementInfo? {
        return self.all[key]
    }

    public override var description: String {
        return "<\(NSStringFromClass(Self.self)): self.all=\(self.all), self.active=\(self.active)>"
    }

    private func isEqual(toInfos infos: EntitlementInfos?) -> Bool {
        guard let infos = infos else {
            return false
        }

        if self === infos {
            return true
        }

        if self.all != infos.all && !NSDictionary(dictionary: infos.all).isEqual(to: self.all) {
            return false
        }

        return true
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? EntitlementInfos else {
            return false
        }

        if object === self {
            return true
        }

        return isEqual(toInfos: object)
    }
}
