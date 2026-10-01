//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageContext.swift
//
//  Created by Josh Holtz on 11/14/24.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageContext: ObservableObject {

    struct VariableContext {

        let mostExpensivePricePerMonth: Double?
        let showZeroDecimalPlacePrices: Bool

        init(packages: [Package], showZeroDecimalPlacePrices: Bool = true) {
            let mostExpensivePricePerMonth = Self.mostExpensivePricePerMonth(in: packages)
            self.init(
                mostExpensivePricePerMonth: mostExpensivePricePerMonth,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            )
        }

        init(mostExpensivePricePerMonth: Double? = nil, showZeroDecimalPlacePrices: Bool = true) {
            self.mostExpensivePricePerMonth = mostExpensivePricePerMonth
            self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        }

        private static func mostExpensivePricePerMonth(in packages: [Package]) -> Double? {
            return packages
                .lazy
                .map(\.storeProduct)
                .compactMap { product in
                    product.pricePerMonth.map {
                        return (
                            product: product,
                            pricePerMonth: $0
                        )
                    }
                }
                .max { productA, productB in
                    return productA.pricePerMonth.doubleValue < productB.pricePerMonth.doubleValue
                }
                .map(\.pricePerMonth.doubleValue)
        }

    }

    @Published var package: Package?
    @Published var variableContext: VariableContext

    /// Whether the last update came from a reconcile rather than a user tap. `TabsComponentView` reads
    /// it so a reconcile isn't recorded as a choice, which would outrank a tab's own default.
    ///
    /// Fragile: it only describes the most recent `update`, so any other write to this context resets
    /// it. Two same-context writes used to, and are now skipped by identity checks. A new write to the
    /// parent context has to pass `isReconcile` deliberately.
    private(set) var lastUpdateWasReconcile: Bool = false

    init(
        package: Package?,
        variableContext: VariableContext
    ) {
        self.package = package
        self.variableContext = variableContext
    }

    /// - Parameter isReconcile: `true` when the SDK moved the selection off a package that wasn't
    ///   rendering, rather than the user tapping. See `lastUpdateWasReconcile`.
    @MainActor
    func update(package: Package?, variableContext: VariableContext, isReconcile: Bool = false) {
        // Set before the published properties so observers see it while handling the change.
        self.lastUpdateWasReconcile = isReconcile
        self.package = package
        self.variableContext = variableContext
    }

}

#endif
