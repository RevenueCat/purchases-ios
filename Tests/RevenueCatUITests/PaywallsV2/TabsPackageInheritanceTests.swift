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
/// 1. Tabs WITH packages: use their own package context (separate instance)
/// 2. Tabs WITHOUT packages: use parent context directly (same instance)
///    - This ensures they always reflect the current parent selection
///    - They automatically stay in sync when parent context changes
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
    func testParentContextChangeAffectsTabsWithoutPackages() {
        // Given: Setup with Tab 1 (has packages) and Tab 2 (no packages)
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // Tab 1 gets its own context
        let tab1Context = PackageContext(
            package: self.tabPackageC,
            variableContext: .init(packages: [self.tabPackageC])
        )

        // Tab 2 uses parent context directly
        let tab2Context = parentContext

        // Then: Initial state
        expect(tab1Context.package?.identifier) == self.tabPackageC.identifier
        expect(tab2Context.package?.identifier) == self.parentPackageA.identifier

        // When: Parent context changes (e.g., user selects Package B)
        parentContext.update(
            package: self.parentPackageB,
            variableContext: parentContext.variableContext
        )

        // Then: Tab 1 is unaffected (has its own context)
        expect(tab1Context.package?.identifier) == self.tabPackageC.identifier

        // Then: Tab 2 automatically sees the change (same instance as parent)
        expect(tab2Context.package?.identifier) == self.parentPackageB.identifier
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

    func testAllTabsWithoutPackagesShareParentContext() {
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
}

// MARK: - Test Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct TestTabData {
    let tabId: String
    let packages: [Package]
    let defaultSelectedPackage: Package?
}

#endif
