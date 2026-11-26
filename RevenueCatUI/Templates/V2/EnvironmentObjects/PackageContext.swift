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

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageContext: ObservableObject {

    struct VariableContext: Equatable {

        let mostExpensivePricePerMonth: StoreProduct.MonthlyPrice?
        /// Used by the absolute and offer discount variables without truncating to two decimal places.
        let exactMostExpensivePricePerMonth: Decimal?
        let showZeroDecimalPlacePrices: Bool

        init(packages: [Package], showZeroDecimalPlacePrices: Bool = true) {
            self.init(
                mostExpensivePricePerMonth: Self.mostExpensivePricePerMonth(in: packages),
                exactMostExpensivePricePerMonth: Self.exactMostExpensivePricePerMonth(in: packages),
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            )
        }

        init(
            mostExpensivePricePerMonth: StoreProduct.MonthlyPrice? = nil,
            exactMostExpensivePricePerMonth: Decimal? = nil,
            showZeroDecimalPlacePrices: Bool = true
        ) {
            self.mostExpensivePricePerMonth = mostExpensivePricePerMonth
            self.exactMostExpensivePricePerMonth = exactMostExpensivePricePerMonth
            self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        }

        private static func exactMostExpensivePricePerMonth(in packages: [Package]) -> Decimal? {
            return packages
                .lazy
                .map(\.storeProduct)
                .compactMap { product -> Decimal? in
                    guard let months = product.subscriptionPeriod?.numberOfUnitsAs(unit: .month), months > 0 else {
                        return nil
                    }
                    return product.price / months
                }
                .max()
        }

        private static func mostExpensivePricePerMonth(in packages: [Package]) -> StoreProduct.MonthlyPrice? {
            return packages
                .lazy
                .compactMap(\.storeProduct.pricePerMonthForDiscount)
                .max()
        }

    }

    /// Selection state shared by duplicate renderings, but isolated to this presentation context.
    final class TabsState {

        // Retain the identity used as the cache key for this presentation's lifetime.
        let viewModel: TabsComponentViewModel
        var contextsByTabId: [String: PackageContext] = [:]
        var parentOwnedPackage: Package?
        var parentOwnedVariableContext: VariableContext
        var didUserSelectPackage = false
        var didSeedInitialState = false

        @MainActor
        private var appearedViewIDs: Set<UUID> = []

        init(parent: PackageContext, viewModel: TabsComponentViewModel) {
            self.viewModel = viewModel
            self.parentOwnedPackage = parent.package
            self.parentOwnedVariableContext = parent.variableContext
        }

        /// Duplicate renderings share appearance tracking within this presentation context.
        /// Returning after every copy disappeared must restore the selected tab's package.
        @MainActor
        func registerAppearance(id: UUID) -> Bool {
            let isFirstAppearance = self.appearedViewIDs.isEmpty
            self.appearedViewIDs.insert(id)
            return isFirstAppearance
        }

        @MainActor
        func unregisterAppearance(id: UUID) {
            self.appearedViewIDs.remove(id)
        }

    }

    private var tabsStatesByIdentifier: [ObjectIdentifier: TabsState] = [:]

    func tabsState(for viewModel: TabsComponentViewModel) -> TabsState {
        let identifier = ObjectIdentifier(viewModel)
        if let state = self.tabsStatesByIdentifier[identifier] { return state }
        let state = TabsState(parent: self, viewModel: viewModel)
        self.tabsStatesByIdentifier[identifier] = state
        return state
    }

    /// A sheet mirrors its selection here for page-level consumers, while owning its own context.
    weak var presentedSheetContext: PackageContext? {
        willSet { self.objectWillChange.send() }
    }

    var isPresentingSheet: Bool { self.presentedSheetContext != nil }

    private var presentedSheetIDs: Set<String> = []
    private var hasOwnSheetPackages = false

    @MainActor
    func activateSheet(
        sheetID: String,
        validator: PackageValidator?,
        selectionContext: PackageSelectionContext,
        preserveCurrentSelection: Bool
    ) -> PackageContext {
        let packages = validator?.packages ?? []
        let hasBeenPresented = self.presentedSheetIDs.insert(sheetID).inserted == false
        let selectedPackage: Package?
        if packages.isEmpty {
            selectedPackage = self.package
        } else if preserveCurrentSelection && hasBeenPresented,
                  let current = self.package,
                  validator?.visiblePackages(in: selectionContext).contains(where: {
                      $0.identifier == current.identifier
                  }) == true {
            selectedPackage = current
        } else {
            selectedPackage = validator?.defaultSelectedPackage(in: selectionContext)
        }
        let context = PackageContext(
            package: selectedPackage,
            variableContext: packages.isEmpty ? self.variableContext : .init(
                packages: packages,
                showZeroDecimalPlacePrices: self.variableContext.showZeroDecimalPlacePrices
            )
        )
        context.hasOwnSheetPackages = !packages.isEmpty
        self.retainedSheetSelection = nil
        self.presentedSheetContext = context
        self.update(package: context.package, variableContext: context.variableContext, isReconcile: true)
        return context
    }

    /// A sheet-only paywall keeps the sheet's final package for the purchase button.
    /// Let the active tab adopt it even when dismissal does not change the parent's package.
    private var retainedSheetSelection: (package: Package, wasManuallySelected: Bool)?

    func dismissSheet(retainingSelection: Bool) {
        if retainingSelection,
           let sheet = self.presentedSheetContext,
           sheet.hasOwnSheetPackages,
           let package = sheet.package {
            self.retainedSheetSelection = (package, sheet.manuallySelectedPackage?.identifier == package.identifier)
            // Tabs without packages restore the parent's selection when they become active.
            // Dismissal can keep the same package, so their cache won't see a package change.
            for state in self.tabsStatesByIdentifier.values {
                state.parentOwnedPackage = package
                state.parentOwnedVariableContext = self.variableContext
            }
        } else {
            self.retainedSheetSelection = nil
        }
        self.presentedSheetContext = nil
    }

    @MainActor
    func adoptRetainedSheetPackage(from parent: PackageContext, tabPackages: [Package]) {
        guard let selection = parent.retainedSheetSelection,
              tabPackages.contains(where: { $0.identifier == selection.package.identifier }) else { return }
        self.update(
            package: selection.package,
            variableContext: self.variableContext,
            isReconcile: !selection.wasManuallySelected
        )
    }

    func clearManualSelection() {
        self.manuallySelectedPackage = nil
    }

    private(set) var manuallySelectedPackage: Package?

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
        if !isReconcile {
            self.manuallySelectedPackage = package
        }
        self.package = package
        self.variableContext = variableContext
    }

}

#endif
