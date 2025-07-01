//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyProductGrant.swift
//
//  Created by RevenueCat on 3/19/24.

import Foundation

/**
 * Information about a virtual currency grant from a product.
 */
@objc(RCVirtualCurrencyProductGrant) public final class VirtualCurrencyProductGrant: NSObject {

    /**
     * The amount of this currency granted by the product.
     */
    @objc public let amount: Int

    @objc
    public init(amount: Int) {
        self.amount = amount
        super.init()
    }

    public override var description: String {
        return """
        <VirtualCurrencyProductGrant {
            amount=\(self.amount)
        }>
        """
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? VirtualCurrencyProductGrant else { return false }

        return self.amount == other.amount
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.amount)

        return hasher.finalize()
    }

}

extension VirtualCurrencyProductGrant: Codable, Sendable {}
