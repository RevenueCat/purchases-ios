//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    private let viewModel: TextComponentViewModel

    internal init(viewModel: TextComponentViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            packageContext: self.packageContext
        ) { style in
            Group {
                if style.visible {
                    Text(style.text)
                        .font(style.fontSize)
                        .fontWeight(style.fontWeight)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(style.horizontalAlignment)
                        .foregroundStyle(style.color)
                        .padding(style.padding)
                        .size(style.size)
                        .background(style.backgroundColor)
                        .padding(style.margin)
                } else {
                    EmptyView()
                }
            }
        }
    }

}

#if DEBUG

// swiftlint:disable identifier_name

import StoreKit

class MockProduct: SK1Product, @unchecked Sendable {

    class MockSubPeriod: SKProductSubscriptionPeriod, @unchecked Sendable {

        let _unit: SKProduct.PeriodUnit

        init(unit: SKProduct.PeriodUnit) {
            self._unit = unit
        }

        override var numberOfUnits: Int {
            return 1
        }

        override var unit: SKProduct.PeriodUnit {
            return self._unit
        }

    }

    let _price: NSDecimalNumber
    let _unit: SKProduct.PeriodUnit
    let _localizedTitle: String

    init(price: NSDecimalNumber, unit: SKProduct.PeriodUnit, localizedTitle: String) {
        self._price = price
        self._unit = unit
        self._localizedTitle = localizedTitle
    }

    override var price: NSDecimalNumber {
        return self._price
    }

    override var subscriptionPeriod: SKProductSubscriptionPeriod? {
        return MockSubPeriod(unit: self._unit)
    }

    override var localizedTitle: String {
        return self._localizedTitle
    }

    override var priceLocale: Locale {
        return Locale(identifier: "en-US")
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TextComponentView_Previews: PreviewProvider {

    static var monthlyPackage: Package = .init(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: .init(sk1Product: MockProduct(
            price: 9.99,
            unit: .month,
            localizedTitle: "Monthly"
        )),
        offeringIdentifier: "default"
    )

    static var annualPackage: Package = .init(
        identifier: "annual",
        packageType: .annual,
        storeProduct: .init(sk1Product: MockProduct(
            price: 99.99,
            unit: .year,
            localizedTitle: "Annual"
        )),
        offeringIdentifier: "default"
    )

    static var previews: some View {
        // Default
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world")
                ],
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default")

        // Customizations
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world")
                ],
                component: .init(
                    text: "id_1",
                    fontName: nil,
                    fontWeight: .black,
                    color: .init(light: .hex("#ff0000")),
                    backgroundColor: .init(light: .hex("#dedede")),
                    padding: .init(top: 10,
                                   bottom: 10,
                                   leading: 20,
                                   trailing: 20),
                    margin: .init(top: 20,
                                  bottom: 20,
                                  leading: 10,
                                  trailing: 10),
                    fontSize: .bodyS,
                    horizontalAlignment: .leading
                )
            )
        )
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Customizations")

        // State - Selected
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Hello, world")
                ],
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: .init(
                        states: .init(
                            selected: .init(
                                fontWeight: .black,
                                color: .init(light: .hex("#ff0000")),
                                backgroundColor: .init(light: .hex("#0000ff")),
                                padding: .init(top: 10,
                                               bottom: 10,
                                               leading: 10,
                                               trailing: 10),
                                margin: .init(top: 10,
                                              bottom: 10,
                                              leading: 10,
                                              trailing: 10),
                                fontSize: .headingXL
                            )
                        )
                    )
                )
            )
        )
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .environment(\.componentViewState, .selected)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("State - Selected")

        // Condition - Medium
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("THIS TEXT SHOULDN'T SHOW"),
                    "id_2": .string("Showing medium condition")
                ],
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: .init(
                        conditions: .init(
                            medium: .init(
                                text: "id_2"
                            )
                        )
                    )
                )
            )
        )
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .environment(\.screenCondition, .medium)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Medium")

        // Condition - Has medium but not medium
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("Showing compact condition"),
                    "id_2": .string("SHOULDN'T SHOW MEDIUM")
                ],
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000")),
                    overrides: .init(
                        conditions: .init(
                            medium: .init(
                                text: "id_2"
                            )
                        )
                    )
                )
            )
        )
        .environmentObject(PackageContext(
            package: nil,
            variableContext: .init())
        )
        .environment(\.screenCondition, .compact)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Condition - Has medium but not medium")

        // Process variable
        TextComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                localizedStrings: [
                    "id_1": .string("{{ product_name }} is {{ price_per_period_full }} ({{ sub_relative_discount }})")
                ],
                component: .init(
                    text: "id_1",
                    color: .init(light: .hex("#000000"))
                )
            )
        )
        .environmentObject(PackageContext(
            package: self.annualPackage,
            variableContext: .init(packages: [self.monthlyPackage, self.annualPackage]))
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Process variable")
    }
}

#endif

#endif
