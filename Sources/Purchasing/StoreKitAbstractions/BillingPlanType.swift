//
//  BillingPlanType.swift
//  RevenueCat
//
//  Created by Will Taylor on 5/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import StoreKit

/// Defines different billing plan types that may be purchased on a product.
@objc(RCBillingPlanType)
public final class BillingPlanType: NSObject, Sendable {
    /// Upfront billing plan, where the user pays in full when purchasing the product.
    @objc(RCUpFront) public static let upFront = BillingPlanType(rawValue: "upFront")

    /// Monthly billing plan, where the user pays in monthly installments.
    @objc(RCMonthly) public static let monthly = BillingPlanType(rawValue: "monthly")

    private init(rawValue: String) {
        self.rawValue = rawValue
        super.init()
    }

    /// String representation of the BillingPlanType.
    @objc public let rawValue: String

    /// Pattern matching operator
    public static func ~= (lhs: BillingPlanType, rhs: BillingPlanType) -> Bool {
        lhs === rhs
    }
}

internal extension BillingPlanType {

    var productPlanIdentifierForCompoundID: String? {
        switch self {
        case .monthly:
            return self.rawValue
        case .upFront:
            return nil
        default:
            return nil
        }
    }

    static func productPlanIdentifierForCompoundID(from rawValue: String?) -> String? {
        switch rawValue {
        case Self.monthly.rawValue:
            return Self.monthly.productPlanIdentifierForCompoundID
        case Self.upFront.rawValue:
            return Self.upFront.productPlanIdentifierForCompoundID
        default:
            return rawValue
        }
    }

}

#if compiler(>=6.3.2)
internal extension BillingPlanType {
    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    static func from(storeKitBillingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType) -> BillingPlanType? {
        switch storeKitBillingPlanType {
        case .monthly:
            return BillingPlanType.monthly
        case .upFront:
            return BillingPlanType.upFront
        default:
            return nil
        }
    }

    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    var skBillingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType? {
        switch self {
        case .monthly:
            return StoreKit.Product.SubscriptionInfo.BillingPlanType.monthly
        case .upFront:
            return StoreKit.Product.SubscriptionInfo.BillingPlanType.upFront
        default:
            return nil
        }
    }
}
#endif
