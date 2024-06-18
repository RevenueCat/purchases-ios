//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesAreCompletedBy.swift
//
//  Created by James Borthwick on 2024-05-30.

import Foundation

/// Where responsibility for completing purchase transactions lies.
@objc(RCPurchasesAreCompletedBy)
public enum PurchasesAreCompletedBy: Int {

    /// Purchase transactions are to be finished by RevenueCat.
    case revenueCat

    /// Purchase transactions are to be finished by your app.
    case myApp

}

extension PurchasesAreCompletedBy {
    var finishTransactions: Bool {
        self == .revenueCat
    }
}

extension PurchasesAreCompletedBy: Sendable {}
