//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomActionDataTests.swift
//
//  Created by Facundo Menzella on 21/07/2025.
//

import Nimble
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, *)
final class CustomActionDataTests: TestCase {

    func testCustomActionDataInitialization() {
        let data = CustomActionData(
            actionIdentifier: "delete_user",
            purchaseIdentifier: "monthly_subscription"
        )

        expect(data.actionIdentifier) == "delete_user"
        expect(data.purchaseIdentifier) == "monthly_subscription"
    }

    func testCustomActionDataInitializationWithNilPurchase() {
        let data = CustomActionData(
            actionIdentifier: "rate_app",
            purchaseIdentifier: nil
        )

        expect(data.actionIdentifier) == "rate_app"
        expect(data.purchaseIdentifier).to(beNil())
    }

    func testCustomActionDataEquality() {
        let data1 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: "product1")
        let data2 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: "product1")
        let data3 = CustomActionData(actionIdentifier: "rate_app", purchaseIdentifier: "product1")
        let data4 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: "product2")
        let data5 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: nil)

        // Test equality
        expect(data1) == data2

        // Test inequality - different action identifiers
        expect(data1) != data3

        // Test inequality - different purchase IDs
        expect(data1) != data4

        // Test inequality - nil vs non-nil purchase ID
        expect(data1) != data5
    }

    func testCustomActionDataHashable() {
        let data1 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: "product1")
        let data2 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: "product1")
        let data3 = CustomActionData(actionIdentifier: "rate_app", purchaseIdentifier: "product1")

        // Equal objects should have equal hash values
        expect(data1.hashValue) == data2.hashValue

        // Different objects should likely have different hash values
        expect(data1.hashValue) != data3.hashValue

        // Test that CustomActionData can be used in Sets
        let dataSet: Set<CustomActionData> = [data1, data2, data3]
        expect(dataSet.count) == 2 // data1 and data2 are equal, so only 2 unique items
    }

    func testCustomActionDataDescription() {
        let dataWithPurchase = CustomActionData(
            actionIdentifier: "delete_user",
            purchaseIdentifier: "monthly_sub"
        )
        let dataWithoutPurchase = CustomActionData(
            actionIdentifier: "rate_app",
            purchaseIdentifier: nil
        )

        expect(dataWithPurchase.description).to(contain("delete_user"))
        expect(dataWithPurchase.description).to(contain("monthly_sub"))
        expect(dataWithPurchase.description).to(contain("CustomActionData"))

        expect(dataWithoutPurchase.description).to(contain("rate_app"))
        expect(dataWithoutPurchase.description).to(contain("no active purchase"))
        expect(dataWithoutPurchase.description).to(contain("CustomActionData"))
    }

    func testCustomActionDataCanBeUsedInDictionaries() {
        let data1 = CustomActionData(actionIdentifier: "delete_user", purchaseIdentifier: "product1")
        let data2 = CustomActionData(actionIdentifier: "rate_app", purchaseIdentifier: nil)

        var actionMap: [CustomActionData: String] = [:]
        actionMap[data1] = "Delete Account"
        actionMap[data2] = "Rate App"

        expect(actionMap[data1]) == "Delete Account"
        expect(actionMap[data2]) == "Rate App"
        expect(actionMap.count) == 2
    }

    func testCustomActionDataWithEmptyStrings() {
        let data = CustomActionData(
            actionIdentifier: "",
            purchaseIdentifier: ""
        )

        expect(data.actionIdentifier) == ""
        expect(data.purchaseIdentifier) == ""

        // Empty strings should still work correctly
        expect(data.description).to(contain("CustomActionData"))
        expect(data.description).to(contain("purchase: "))
    }

    func testCustomActionDataWithLongStrings() {
        let longActionId = String(repeating: "a", count: 1000)
        let longPurchaseId = String(repeating: "b", count: 1000)

        let data = CustomActionData(
            actionIdentifier: longActionId,
            purchaseIdentifier: longPurchaseId
        )

        expect(data.actionIdentifier) == longActionId
        expect(data.purchaseIdentifier) == longPurchaseId
        expect(data.actionIdentifier.count) == 1000
        expect(data.purchaseIdentifier?.count) == 1000
    }
}
