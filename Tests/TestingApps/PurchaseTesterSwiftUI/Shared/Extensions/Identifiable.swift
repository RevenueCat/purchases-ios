//
//  Identifiable.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import RevenueCat

extension StoreProduct: Identifiable {

    public var id: String {
        return self.productIdentifier
    }

}

extension NonSubscriptionTransaction: Identifiable {

    public var id: String {
        return self.productIdentifier
    }

}
