//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsPackageInheritanceTests.swift
//
//  Created by RevenueCat on 12/11/24.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

// MARK: - TabsPackageInheritanceTests

/// Tests for package inheritance behavior in the Tabs component.
///
/// These tests verify the following requirements:
///
/// 1. **Context Creation:**
///    - Tabs WITH packages: use their own package context (separate instance)
///    - Tabs WITHOUT packages: use parent context directly (same instance)
///
/// 2. **Tab Switching:**
///    - Switching to tab WITHOUT packages → restore `parentOwnedPackage`
///    - Switching to tab WITH packages, parent's package IS in tab → keep parent's selection
///    - Switching to tab WITH packages, parent's package NOT in tab → use tab's default
///
/// 3. **Parent Selection Tracking:**
///    - Tab propagation (newPackage == tab's current) → don't update `parentOwnedPackage`
///    - User selection (newPackage != tab's current) → update `parentOwnedPackage`
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class TabsPackageInheritanceTests: TestCase {

    // MARK: - Test Data

    /// Parent Package A - marked as default
    private var parentPackageA: Package {
        Package(
            identifier: "parent_package_a",
            packageType: .custom,
            storeProduct: TestData.monthlyProduct.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    /// Parent Package B
    private var parentPackageB: Package {
        Package(
            identifier: "parent_package_b",
            packageType: .custom,
            storeProduct: TestData.annualProduct.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    /// Tab Package C - belongs to Tab 1
    private var tabPackageC: Package {
        Package(
            identifier: "tab_package_c",
            packageType: .custom,
            storeProduct: TestData.weeklyProduct.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    // MARK: - Package Context Creation Tests

    func testTabWithPackagesGetsOwnContext() {
        // Given: A tab with its own packages
        let tabViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )

        // Given: A parent context with a different package
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Creating package context for the tab (simulating the init logic)
        let tabPackageContext: PackageContext
        if !tabViewModel.packages.isEmpty {
            tabPackageContext = PackageContext(
                package: tabViewModel.defaultSelectedPackage,
                variableContext: .init(
                    packages: tabViewModel.packages,
                    showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
                )
            )
        } else {
            tabPackageContext = parentContext
        }

        // Then: Tab should use its own package, not the parent's
        expect(tabPackageContext.package?.identifier) == self.tabPackageC.identifier
        expect(tabPackageContext.package?.identifier) != self.parentPackageA.identifier

        // Then: Tab context should be a different instance than parent
        expect(tabPackageContext) !== parentContext
    }

    func testTabWithoutPackagesUsesParentContextDirectly() {
        // Given: A tab without packages
        let tabViewModel = TestTabData(
            tabId: "tab2",
            packages: [],
            defaultSelectedPackage: nil
        )

        // Given: A parent context with a package
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Creating package context for the tab (simulating the init logic)
        let tabPackageContext: PackageContext
        if !tabViewModel.packages.isEmpty {
            tabPackageContext = PackageContext(
                package: tabViewModel.defaultSelectedPackage,
                variableContext: .init(
                    packages: tabViewModel.packages,
                    showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
                )
            )
        } else {
            tabPackageContext = parentContext
        }

        // Then: Tab should use the SAME instance as parent (not a copy)
        expect(tabPackageContext) === parentContext
        expect(tabPackageContext.package?.identifier) == self.parentPackageA.identifier
    }

    @MainActor
    func testTabWithoutPackagesAutomaticallySeesParentChanges() {
        // Given: A parent context
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // Given: A tab without packages using parent context directly
        let tabPackageContext = parentContext // Same instance

        // Then: Initially both have Package A
        expect(tabPackageContext.package?.identifier) == self.parentPackageA.identifier

        // When: Parent context changes to Package B
        parentContext.update(
            package: self.parentPackageB,
            variableContext: parentContext.variableContext
        )

        // Then: Tab context automatically sees the change (same instance)
        expect(tabPackageContext.package?.identifier) == self.parentPackageB.identifier
    }

    // MARK: - Integration Tests

    func testCompletePackageContextSetup() {
        // This test simulates the complete init flow:
        // - Parent has Package A (default) and Package B
        // - Tab 1 has Package C
        // - Tab 2 has no packages (uses parent context directly)

        // Given: Tab view models
        let tab1ViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )
        let tab2ViewModel = TestTabData(
            tabId: "tab2",
            packages: [],
            defaultSelectedPackage: nil
        )

        let tabViewModels: [String: TestTabData] = [
            "tab1": tab1ViewModel,
            "tab2": tab2ViewModel
        ]

        // Given: Parent context with default package A
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Creating tier package contexts (simulating init logic)
        var tierPackageContexts: [String: PackageContext] = [:]
        for (tabId, tabViewModel) in tabViewModels {
            if !tabViewModel.packages.isEmpty {
                tierPackageContexts[tabId] = PackageContext(
                    package: tabViewModel.defaultSelectedPackage,
                    variableContext: .init(
                        packages: tabViewModel.packages,
                        showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
                    )
                )
            } else {
                tierPackageContexts[tabId] = parentContext
            }
        }

        // Then: Tab 1 should have its own package (different instance)
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.tabPackageC.identifier
        expect(tierPackageContexts["tab1"]) !== parentContext

        // Then: Tab 2 should be the same instance as parent
        expect(tierPackageContexts["tab2"]) === parentContext
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageA.identifier
    }

    @MainActor
    func testUserSelectionUpdatesParentOwnedPackage() {
        // Given: Setup simulating the parentOwnedPackage tracking
        var parentOwnedPackage: Package? = self.parentPackageA
        var parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: parentOwnedVariableContext
        )

        // Tab 1 has its own package
        let tab1Context = PackageContext(
            package: self.tabPackageC,
            variableContext: .init(packages: [self.tabPackageC])
        )

        // Simulate: User selects Package B while on Tab 1
        parentContext.update(
            package: self.parentPackageB,
            variableContext: parentContext.variableContext
        )

        // Simulate the onChangeOf handler - detect if this is a tab propagation
        let tabHasNoPackages = false // Tab 1 has packages
        let isTabPropagation = !tabHasNoPackages &&
            parentContext.package?.identifier == tab1Context.package?.identifier

        // Then: This is NOT a tab propagation (B != C)
        expect(isTabPropagation) == false

        // When: It's a user selection, update parentOwnedPackage
        if !isTabPropagation {
            parentOwnedPackage = parentContext.package
            parentOwnedVariableContext = parentContext.variableContext
        }

        // Then: parentOwnedPackage is updated to B
        expect(parentOwnedPackage?.identifier) == self.parentPackageB.identifier
    }

    func testAllTabsWithPackagesGetOwnContexts() {
        // Given: All tabs have their own packages
        let tab1ViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )
        let tab2ViewModel = TestTabData(
            tabId: "tab2",
            packages: [self.parentPackageB],
            defaultSelectedPackage: self.parentPackageB
        )

        let tabViewModels: [String: TestTabData] = [
            "tab1": tab1ViewModel,
            "tab2": tab2ViewModel
        ]

        // Given: Parent context
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA])
        )

        // When: Creating tier package contexts
        var tierPackageContexts: [String: PackageContext] = [:]
        for (tabId, tabViewModel) in tabViewModels {
            if !tabViewModel.packages.isEmpty {
                tierPackageContexts[tabId] = PackageContext(
                    package: tabViewModel.defaultSelectedPackage,
                    variableContext: .init(packages: tabViewModel.packages)
                )
            } else {
                tierPackageContexts[tabId] = parentContext
            }
        }

        // Then: Each tab should have its own context (different instances)
        expect(tierPackageContexts["tab1"]) !== parentContext
        expect(tierPackageContexts["tab2"]) !== parentContext
        expect(tierPackageContexts["tab1"]) !== tierPackageContexts["tab2"]

        // Then: Each tab has its own package
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.tabPackageC.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageB.identifier
    }

    @MainActor
    func testAllTabsWithoutPackagesShareParentContextAndUpdateTogether() {
        // Given: All tabs have no packages
        let tab1ViewModel = TestTabData(tabId: "tab1", packages: [], defaultSelectedPackage: nil)
        let tab2ViewModel = TestTabData(tabId: "tab2", packages: [], defaultSelectedPackage: nil)
        let tab3ViewModel = TestTabData(tabId: "tab3", packages: [], defaultSelectedPackage: nil)

        let tabViewModels: [String: TestTabData] = [
            "tab1": tab1ViewModel,
            "tab2": tab2ViewModel,
            "tab3": tab3ViewModel
        ]

        // Given: Parent context
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Creating tier package contexts
        var tierPackageContexts: [String: PackageContext] = [:]
        for (tabId, tabViewModel) in tabViewModels {
            if !tabViewModel.packages.isEmpty {
                tierPackageContexts[tabId] = PackageContext(
                    package: tabViewModel.defaultSelectedPackage,
                    variableContext: .init(packages: tabViewModel.packages)
                )
            } else {
                tierPackageContexts[tabId] = parentContext
            }
        }

        // Then: All tabs should be the same instance as parent
        expect(tierPackageContexts["tab1"]) === parentContext
        expect(tierPackageContexts["tab2"]) === parentContext
        expect(tierPackageContexts["tab3"]) === parentContext

        // Then: All tabs start with Package A
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.parentPackageA.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageA.identifier
        expect(tierPackageContexts["tab3"]?.package?.identifier) == self.parentPackageA.identifier

        // When: Parent context changes to Package B
        parentContext.update(
            package: self.parentPackageB,
            variableContext: parentContext.variableContext
        )

        // Then: ALL tabs see the change simultaneously (they're all the same instance)
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.parentPackageB.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageB.identifier
        expect(tierPackageContexts["tab3"]?.package?.identifier) == self.parentPackageB.identifier
    }

    func testParentContextWithNilPackage() {
        // Given: A tab without packages
        let tabViewModel = TestTabData(tabId: "tab1", packages: [], defaultSelectedPackage: nil)

        // Given: Parent context with NO package (nil)
        let parentContext = PackageContext(
            package: nil,
            variableContext: .init(packages: [])
        )

        // When: Creating package context for the tab
        let tabPackageContext: PackageContext
        if !tabViewModel.packages.isEmpty {
            tabPackageContext = PackageContext(
                package: tabViewModel.defaultSelectedPackage,
                variableContext: .init(packages: tabViewModel.packages)
            )
        } else {
            tabPackageContext = parentContext
        }

        // Then: Tab uses parent context (same instance), which has nil package
        expect(tabPackageContext) === parentContext
        expect(tabPackageContext.package).to(beNil())
    }

    func testVariableContextIsPreservedForTabsWithPackages() {
        // Given: A tab with its own packages
        let tabViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )

        // Given: Parent context with specific settings
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(
                packages: [self.parentPackageA, self.parentPackageB],
                showZeroDecimalPlacePrices: true
            )
        )

        // When: Creating package context for the tab
        let tabPackageContext = PackageContext(
            package: tabViewModel.defaultSelectedPackage,
            variableContext: .init(
                packages: tabViewModel.packages,
                showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
            )
        )

        // Then: Tab preserves the showZeroDecimalPlacePrices setting from parent
        expect(tabPackageContext.variableContext.showZeroDecimalPlacePrices) == true

        // Then: Tab has its own package
        expect(tabPackageContext.package?.identifier) == self.tabPackageC.identifier
    }

    // MARK: - Additional Edge Case Tests

    func testVariableContextIsComputedFromTabPackagesNotParent() {
        // Given: A tab with its own package (weekly - cheaper per month)
        let tabViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC], // weekly product
            defaultSelectedPackage: self.tabPackageC
        )

        // Given: Parent context with different packages (monthly + annual - different prices)
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Creating package context for the tab
        let tabPackageContext = PackageContext(
            package: tabViewModel.defaultSelectedPackage,
            variableContext: .init(
                packages: tabViewModel.packages,
                showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
            )
        )

        // Then: Tab's mostExpensivePricePerMonth is computed from TAB's packages
        // The tab has only the weekly product, so its mostExpensivePricePerMonth
        // should be different from the parent's (which has monthly + annual)
        expect(tabPackageContext.variableContext.mostExpensivePricePerMonth)
            != parentContext.variableContext.mostExpensivePricePerMonth
    }

    func testTabWithSamePackagesAsParent() {
        // Given: A tab with the SAME packages as the parent
        // This tests the case where a tab explicitly defines packages that match the parent's
        let tabViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.parentPackageA, self.parentPackageB],
            defaultSelectedPackage: self.parentPackageB // Different default than parent
        )

        // Given: Parent context with the same packages but different default
        let parentContext = PackageContext(
            package: self.parentPackageA, // Parent defaults to Package A
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Creating package context for the tab (simulating the init logic)
        let tabPackageContext: PackageContext
        if !tabViewModel.packages.isEmpty {
            tabPackageContext = PackageContext(
                package: tabViewModel.defaultSelectedPackage,
                variableContext: .init(
                    packages: tabViewModel.packages,
                    showZeroDecimalPlacePrices: parentContext.variableContext.showZeroDecimalPlacePrices
                )
            )
        } else {
            tabPackageContext = parentContext
        }

        // Then: Tab should have its OWN context (different instance), even with same packages
        expect(tabPackageContext) !== parentContext

        // Then: Tab should use its own default (Package B), not parent's default (Package A)
        expect(tabPackageContext.package?.identifier) == self.parentPackageB.identifier
        expect(tabPackageContext.package?.identifier) != self.parentPackageA.identifier
    }

    @MainActor
    func testTabPropagationDoesNotUpdateParentOwnedPackage() {
        // This test verifies that when a tab propagates its package to the parent,
        // parentOwnedPackage is NOT updated (avoiding incorrect restoration later).
        //
        // Scenario:
        // 1. parentOwnedPackage = A
        // 2. Tab 1 (has Package C) propagates C to parent
        // 3. parentOwnedPackage should still be A (not C)

        // Given: Initial parentOwnedPackage is A
        var parentOwnedPackage: Package? = self.parentPackageA

        // Given: Tab has Package C
        let tabContext = PackageContext(
            package: self.tabPackageC,
            variableContext: .init(packages: [self.tabPackageC])
        )

        // Given: Parent context
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Tab propagates its package to parent
        parentContext.update(
            package: self.tabPackageC,
            variableContext: tabContext.variableContext
        )

        // Simulate the onChangeOf handler - detect if this is a tab propagation
        let tabHasNoPackages = false // Tab has packages
        let isTabPropagation = !tabHasNoPackages &&
            parentContext.package?.identifier == tabContext.package?.identifier

        // Then: This IS a tab propagation (C == C)
        expect(isTabPropagation) == true

        // When: It's a tab propagation, don't update parentOwnedPackage
        if !isTabPropagation {
            parentOwnedPackage = parentContext.package
        }

        // Then: parentOwnedPackage is still A (not updated to C)
        expect(parentOwnedPackage?.identifier) == self.parentPackageA.identifier
    }

    // MARK: - Tab Switching Tests

    @MainActor
    func testSwitchingToTabWithoutPackagesRestoresParentOwnedPackage() {
        // Scenario:
        // 1. parentOwnedPackage = A
        // 2. Tab 1 (has Package C) propagates C to parent → parent now has C
        // 3. Switch to Tab 2 (no packages) → parent should be restored to A

        // Given: Initial parentOwnedPackage is A
        let parentOwnedPackage: Package? = self.parentPackageA
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        let updatePlan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: parentOwnedPackage,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: [],
            tabDefaultPackage: nil
        )

        // Then: Parent is restored to A
        expect(updatePlan.parentUpdate?.package?.identifier) == self.parentPackageA.identifier
        expect(updatePlan.tabUpdate).to(beNil())
    }

    @MainActor
    func testSwitchingToTabWithPackagesKeepsParentSelectionIfInTab() {
        // Scenario:
        // 1. parentOwnedPackage = B
        // 2. Tab 2 has packages [A, B, C] with default A
        // 3. Switch to Tab 2 → Tab 2 should show B (parent's selection, which is in tab)

        // Given: parentOwnedPackage is B
        let parentOwnedPackage: Package? = self.parentPackageB
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        // Given: Tab 2 has packages including B
        let tab2Packages = [self.parentPackageA, self.parentPackageB, self.tabPackageC]
        let tab2PackageIdentifiers = Set(tab2Packages.map(\.identifier))

        let updatePlan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: parentOwnedPackage,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: tab2Packages,
            tabDefaultPackage: self.parentPackageA
        )

        // Then: Tab 2 shows B (parent's selection)
        expect(updatePlan.tabUpdate?.package?.identifier) == self.parentPackageB.identifier
        expect(updatePlan.parentUpdate?.package?.identifier) == self.parentPackageB.identifier
    }

    @MainActor
    func testSwitchingToTabWithPackagesUsesTabVariableContextWhenParentPackageIsInTab() {
        // Scenario:
        // 1. parentOwnedPackage = B with parent variable context [A, B]
        // 2. Tab has packages [B, C] (different package set)
        // 3. Switch to Tab → should keep B, but variableContext should reflect TAB packages [B, C]

        // Given: parent-owned selection and variable context
        let parentOwnedPackage: Package? = self.parentPackageB
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        // Given: Tab packages differ from parent packages
        let tabPackages = [self.parentPackageB, self.tabPackageC]
        let updatePlan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: parentOwnedPackage,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: tabPackages,
            tabDefaultPackage: self.parentPackageB
        )

        // Then: Tab should use its own variable context (from tab packages), not the parent's
        let expectedVariableContext = PackageContext.VariableContext(packages: tabPackages)
        expect(updatePlan.tabUpdate?.variableContext.mostExpensivePricePerMonth)
            == expectedVariableContext.mostExpensivePricePerMonth
    }

    @MainActor
    func testSwitchingToTabWithPackagesUsesDefaultIfParentNotInTab() {
        // Scenario:
        // 1. parentOwnedPackage = A
        // 2. Tab 1 has packages [C] with default C
        // 3. Switch to Tab 1 → Tab 1 should show C (its default, since A is not in tab)

        // Given: parentOwnedPackage is A
        let parentOwnedPackage: Package? = self.parentPackageA

        // Given: Tab 1 has only Package C
        let tab1Packages = [self.tabPackageC]
        let updatePlan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: parentOwnedPackage,
            parentOwnedVariableContext: .init(packages: [self.parentPackageA, self.parentPackageB]),
            parentCurrentVariableContext: .init(packages: [self.parentPackageA, self.parentPackageB]),
            tabPackages: tab1Packages,
            tabDefaultPackage: self.tabPackageC
        )

        // Then: Tab 1 shows C (its default)
        expect(updatePlan.tabUpdate?.package?.identifier) == self.tabPackageC.identifier

        // Then: Parent is updated to C
        expect(updatePlan.parentUpdate?.package?.identifier) == self.tabPackageC.identifier
    }

    @MainActor
    func testCompleteTabSwitchingFlow() {
        // Complete integration test:
        // 1. Start with parentOwnedPackage = A
        // 2. Switch to Tab 1 (has C, A not in tab) → Tab 1 shows C
        // 3. User selects B in parent scope → parentOwnedPackage = B (tracked)
        // 4. Switch to Tab 2 (no packages) → restore B

        // Given: Initial state
        var parentOwnedPackage: Package? = self.parentPackageA
        var parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: parentOwnedVariableContext
        )

        let tab1Context = PackageContext(
            package: self.tabPackageC,
            variableContext: .init(packages: [self.tabPackageC])
        )

        // Step 1: Initial parentOwnedPackage
        expect(parentOwnedPackage?.identifier) == self.parentPackageA.identifier

        // Step 2: Switch to Tab 1 (A not in tab) → use default C, propagate to parent
        let tab1PackageIdentifiers = Set([self.tabPackageC].map(\.identifier))
        let parentInTab1 = parentOwnedPackage.map { tab1PackageIdentifiers.contains($0.identifier) } ?? false
        expect(parentInTab1) == false

        // Tab 1 propagates C to parent
        parentContext.update(
            package: self.tabPackageC,
            variableContext: tab1Context.variableContext
        )

        // This is a tab propagation, don't update parentOwnedPackage
        let isTabPropagation = parentContext.package?.identifier == tab1Context.package?.identifier
        expect(isTabPropagation) == true
        // parentOwnedPackage stays A

        // Step 3: User selects B in parent scope
        parentContext.update(
            package: self.parentPackageB,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // This is NOT a tab propagation (B != C)
        let isUserSelection = parentContext.package?.identifier != tab1Context.package?.identifier
        expect(isUserSelection) == true

        // Update parentOwnedPackage
        parentOwnedPackage = parentContext.package
        parentOwnedVariableContext = parentContext.variableContext
        expect(parentOwnedPackage?.identifier) == self.parentPackageB.identifier

        // Step 4: Switch to Tab 2 (no packages) → restore parentOwnedPackage (B)
        parentContext.update(
            package: parentOwnedPackage,
            variableContext: parentOwnedVariableContext
        )

        // Then: Parent shows B
        expect(parentContext.package?.identifier) == self.parentPackageB.identifier
    }

    @MainActor
    func testClearingParentPackageShouldUpdateParentOwnedPackage() {
        // Scenario:
        // 1. parentOwnedPackage = A
        // 2. Parent selection cleared (nil)
        // Expected: parentOwnedPackage becomes nil (so package-less tabs restore nil)

        // Given: Initial parent-owned selection
        var parentOwnedPackage: Package? = self.parentPackageA
        var parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: parentOwnedVariableContext
        )

        // When: Parent selection is cleared
        parentContext.update(
            package: nil,
            variableContext: parentContext.variableContext
        )

        // Simulate updated onChangeOf handler behavior (explicit nil handling)
        if parentContext.package == nil {
            parentOwnedPackage = nil
            parentOwnedVariableContext = parentContext.variableContext
        } else if let newPackage = parentContext.package {
            parentOwnedPackage = newPackage
            parentOwnedVariableContext = parentContext.variableContext
        }

        // Then: parentOwnedPackage should be nil (broken today)
        expect(parentOwnedPackage).to(beNil())
        expect(parentOwnedVariableContext.showZeroDecimalPlacePrices)
            == parentContext.variableContext.showZeroDecimalPlacePrices
    }
}

// MARK: - Test Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct TestTabData {
    let tabId: String
    let packages: [Package]
    let defaultSelectedPackage: Package?
}

#endif
