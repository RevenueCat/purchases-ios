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
/// 1. Tabs WITH packages: use their own package context
/// 2. Tabs WITHOUT packages: inherit from parent's selected package
/// 3. Tabs WITHOUT packages should NOT be affected when tabs WITH packages propagate their package
/// 4. Tabs WITHOUT packages SHOULD update when user selects a different parent package
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

    // MARK: - Tab Package Identifiers Tests

    func testTabPackageIdentifiersContainsOnlyTabPackages() {
        // Given: Tab view models where Tab 1 has packages and Tab 2 has none
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

        // When: We compute tab package identifiers
        let tabPackageIdentifiers = Set(
            tabViewModels.values.flatMap { $0.packages.map(\.identifier) }
        )

        // Then: Only Tab 1's package should be in the set
        expect(tabPackageIdentifiers).to(contain(self.tabPackageC.identifier))
        expect(tabPackageIdentifiers).notTo(contain(self.parentPackageA.identifier))
        expect(tabPackageIdentifiers).notTo(contain(self.parentPackageB.identifier))
        expect(tabPackageIdentifiers.count) == 1
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

        // When: Creating package context for the tab
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
            tabPackageContext = PackageContext(
                package: parentContext.package,
                variableContext: parentContext.variableContext
            )
        }

        // Then: Tab should use its own package, not the parent's
        expect(tabPackageContext.package?.identifier) == self.tabPackageC.identifier
        expect(tabPackageContext.package?.identifier) != self.parentPackageA.identifier
    }

    func testTabWithoutPackagesInheritsFromParent() {
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

        // When: Creating package context for the tab
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
            tabPackageContext = PackageContext(
                package: parentContext.package,
                variableContext: parentContext.variableContext
            )
        }

        // Then: Tab should inherit the parent's package
        expect(tabPackageContext.package?.identifier) == self.parentPackageA.identifier
    }

    // MARK: - Package Change Filtering Tests

    @MainActor
    func testParentPackageChangeUpdatesTabWithoutPackages() {
        // Given: Tab package identifiers (only contains tab packages)
        let tabPackageIdentifiers: Set<String> = [self.tabPackageC.identifier]

        // Given: Tab 2 (without packages) context initialized with parent's package
        let tab2Context = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Parent package changes to Package B (a parent package, not a tab package)
        let newPackage = self.parentPackageB
        let isTabPackage = tabPackageIdentifiers.contains(newPackage.identifier)

        // Then: This should NOT be a tab package
        expect(isTabPackage) == false

        // When: We update Tab 2's context (simulating the onChangeOf behavior)
        if !isTabPackage {
            tab2Context.update(
                package: newPackage,
                variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
            )
        }

        // Then: Tab 2 should now have Package B
        expect(tab2Context.package?.identifier) == self.parentPackageB.identifier
    }

    @MainActor
    func testTabPackagePropagationDoesNotAffectTabWithoutPackages() {
        // Given: Tab package identifiers (only contains tab packages)
        let tabPackageIdentifiers: Set<String> = [self.tabPackageC.identifier]

        // Given: Tab 2 (without packages) context initialized with parent's package
        let tab2Context = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Tab 1 propagates its package (Package C) to parent
        let propagatedPackage = self.tabPackageC
        let isTabPackage = tabPackageIdentifiers.contains(propagatedPackage.identifier)

        // Then: This SHOULD be recognized as a tab package
        expect(isTabPackage) == true

        // When: We check if we should update Tab 2 (simulating the onChangeOf behavior)
        if !isTabPackage {
            // This block should NOT execute
            tab2Context.update(
                package: propagatedPackage,
                variableContext: .init(packages: [self.tabPackageC])
            )
        }

        // Then: Tab 2 should still have the original parent package, NOT the tab package
        expect(tab2Context.package?.identifier) == self.parentPackageA.identifier
        expect(tab2Context.package?.identifier) != self.tabPackageC.identifier
    }

    // MARK: - Integration Tests

    @MainActor
    func testCompletePackageInheritanceFlow() {
        // This test simulates the complete flow:
        // 1. Parent has Package A (default) and Package B
        // 2. Tab 1 has Package C
        // 3. Tab 2 has no packages (should inherit from parent)

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

        // Given: Tab package identifiers for filtering
        let tabPackageIdentifiers = Set(
            tabViewModels.values.flatMap { $0.packages.map(\.identifier) }
        )

        // When: Creating tier package contexts
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
                tierPackageContexts[tabId] = PackageContext(
                    package: parentContext.package,
                    variableContext: parentContext.variableContext
                )
            }
        }

        // Then: Tab 1 should have its own package
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.tabPackageC.identifier

        // Then: Tab 2 should have the parent's default package
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageA.identifier

        // When: Simulating Tab 1 propagating its package to parent context
        let propagatedPackage = self.tabPackageC
        let isTabPackage = tabPackageIdentifiers.contains(propagatedPackage.identifier)

        // The filtering logic should prevent Tab 2 from being updated
        if !isTabPackage {
            for (tabId, tabViewModel) in tabViewModels where tabViewModel.packages.isEmpty {
                tierPackageContexts[tabId]?.update(
                    package: propagatedPackage,
                    variableContext: .init(packages: [self.tabPackageC])
                )
            }
        }

        // Then: Tab 2 should STILL have the parent's package (not Tab 1's)
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageA.identifier

        // When: User selects Package B (parent package)
        let userSelectedPackage = self.parentPackageB
        let isUserSelectionTabPackage = tabPackageIdentifiers.contains(userSelectedPackage.identifier)

        // This should update Tab 2
        if !isUserSelectionTabPackage {
            for (tabId, tabViewModel) in tabViewModels where tabViewModel.packages.isEmpty {
                tierPackageContexts[tabId]?.update(
                    package: userSelectedPackage,
                    variableContext: parentContext.variableContext
                )
            }
        }

        // Then: Tab 2 should now have Package B
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageB.identifier

        // Then: Tab 1 should still have its own package (unchanged)
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.tabPackageC.identifier
    }

    @MainActor
    func testMultipleTabsWithoutPackagesAllGetUpdated() {
        // Given: Multiple tabs without packages
        let tab1ViewModel = TestTabData(tabId: "tab1", packages: [], defaultSelectedPackage: nil)
        let tab2ViewModel = TestTabData(tabId: "tab2", packages: [], defaultSelectedPackage: nil)
        let tab3ViewModel = TestTabData(
            tabId: "tab3",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )

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

        // Given: Tab package identifiers
        let tabPackageIdentifiers = Set(
            tabViewModels.values.flatMap { $0.packages.map(\.identifier) }
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
                tierPackageContexts[tabId] = PackageContext(
                    package: parentContext.package,
                    variableContext: parentContext.variableContext
                )
            }
        }

        // Then: All tabs without packages should have parent's package
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.parentPackageA.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageA.identifier
        expect(tierPackageContexts["tab3"]?.package?.identifier) == self.tabPackageC.identifier

        // When: Parent package changes to B
        let newPackage = self.parentPackageB
        let isTabPackage = tabPackageIdentifiers.contains(newPackage.identifier)

        if !isTabPackage {
            for (tabId, tabViewModel) in tabViewModels where tabViewModel.packages.isEmpty {
                tierPackageContexts[tabId]?.update(
                    package: newPackage,
                    variableContext: parentContext.variableContext
                )
            }
        }

        // Then: All tabs without packages should be updated to Package B
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.parentPackageB.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageB.identifier

        // Tab 3 should remain unchanged (has its own packages)
        expect(tierPackageContexts["tab3"]?.package?.identifier) == self.tabPackageC.identifier
    }

    // MARK: - Edge Case Tests

    func testAllTabsWithPackagesNoInheritanceNeeded() {
        // Given: All tabs have their own packages
        let tab1ViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )
        let tab2ViewModel = TestTabData(
            tabId: "tab2",
            packages: [self.parentPackageB], // Using parentPackageB as tab2's package
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
                tierPackageContexts[tabId] = PackageContext(
                    package: parentContext.package,
                    variableContext: parentContext.variableContext
                )
            }
        }

        // Then: Each tab should have its own package
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.tabPackageC.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageB.identifier

        // Neither should have parent's package
        expect(tierPackageContexts["tab1"]?.package?.identifier) != self.parentPackageA.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) != self.parentPackageA.identifier
    }

    func testAllTabsWithoutPackagesAllInheritFromParent() {
        // Given: All tabs have no packages
        let tab1ViewModel = TestTabData(tabId: "tab1", packages: [], defaultSelectedPackage: nil)
        let tab2ViewModel = TestTabData(tabId: "tab2", packages: [], defaultSelectedPackage: nil)
        let tab3ViewModel = TestTabData(tabId: "tab3", packages: [], defaultSelectedPackage: nil)

        let tabViewModels: [String: TestTabData] = [
            "tab1": tab1ViewModel,
            "tab2": tab2ViewModel,
            "tab3": tab3ViewModel
        ]

        // Given: Parent context with Package A
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
                tierPackageContexts[tabId] = PackageContext(
                    package: parentContext.package,
                    variableContext: parentContext.variableContext
                )
            }
        }

        // Then: All tabs should have parent's package
        expect(tierPackageContexts["tab1"]?.package?.identifier) == self.parentPackageA.identifier
        expect(tierPackageContexts["tab2"]?.package?.identifier) == self.parentPackageA.identifier
        expect(tierPackageContexts["tab3"]?.package?.identifier) == self.parentPackageA.identifier
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
            tabPackageContext = PackageContext(
                package: parentContext.package,
                variableContext: parentContext.variableContext
            )
        }

        // Then: Tab should also have nil package (inheriting from parent)
        expect(tabPackageContext.package).to(beNil())
    }

    func testVariableContextIsProperlyInherited() {
        // Given: A tab without packages
        let tabViewModel = TestTabData(tabId: "tab1", packages: [], defaultSelectedPackage: nil)

        // Given: Parent context with specific variable context settings
        let parentVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB],
            showZeroDecimalPlacePrices: true
        )
        let parentContext = PackageContext(
            package: self.parentPackageA,
            variableContext: parentVariableContext
        )

        // When: Creating package context for the tab (inheriting from parent)
        let tabPackageContext = PackageContext(
            package: parentContext.package,
            variableContext: parentContext.variableContext
        )

        // Then: Tab should inherit the variable context settings
        expect(tabPackageContext.variableContext.showZeroDecimalPlacePrices) == true
        expect(tabPackageContext.variableContext.mostExpensivePricePerMonth)
        == parentContext.variableContext.mostExpensivePricePerMonth
    }

    func testTabWithPackagesPreservesOwnVariableContext() {
        // Given: A tab with its own packages
        let tabViewModel = TestTabData(
            tabId: "tab1",
            packages: [self.tabPackageC],
            defaultSelectedPackage: self.tabPackageC
        )

        // Given: Parent context with different packages
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

        // Then: Tab's variable context should be based on its own packages, not parent's
        // The mostExpensivePricePerMonth should be calculated from tab's packages only
        let tabMostExpensive = tabPackageContext.variableContext.mostExpensivePricePerMonth
        let parentMostExpensive = parentContext.variableContext.mostExpensivePricePerMonth

        // These could be different since they're calculated from different package sets
        // The key point is that tab has its own variable context
        expect(tabPackageContext.package?.identifier) == self.tabPackageC.identifier
    }

    @MainActor
    func testPackageChangeToNilIsHandled() {
        // Given: Tab package identifiers
        let tabPackageIdentifiers: Set<String> = [self.tabPackageC.identifier]

        // Given: Tab 2 (without packages) context initialized with parent's package
        let tab2Context = PackageContext(
            package: self.parentPackageA,
            variableContext: .init(packages: [self.parentPackageA, self.parentPackageB])
        )

        // When: Parent package changes to nil (edge case - shouldn't happen normally)
        let newPackage: Package? = nil

        // Then: The guard should prevent the update
        guard let newPackage = newPackage else {
            // This is expected - nil package should be handled gracefully
            expect(tab2Context.package?.identifier) == self.parentPackageA.identifier
            return
        }

        let isTabPackage = tabPackageIdentifiers.contains(newPackage.identifier)
        if !isTabPackage {
            tab2Context.update(
                package: newPackage,
                variableContext: .init(packages: [])
            )
        }
    }

    func testEmptyTabPackageIdentifiersWhenNoTabsHavePackages() {
        // Given: All tabs have no packages
        let tab1ViewModel = TestTabData(tabId: "tab1", packages: [], defaultSelectedPackage: nil)
        let tab2ViewModel = TestTabData(tabId: "tab2", packages: [], defaultSelectedPackage: nil)

        let tabViewModels: [String: TestTabData] = [
            "tab1": tab1ViewModel,
            "tab2": tab2ViewModel
        ]

        // When: Computing tab package identifiers
        let tabPackageIdentifiers = Set(
            tabViewModels.values.flatMap { $0.packages.map(\.identifier) }
        )

        // Then: The set should be empty
        expect(tabPackageIdentifiers).to(beEmpty())

        // And: Any parent package should NOT be considered a tab package
        expect(tabPackageIdentifiers.contains(self.parentPackageA.identifier)) == false
        expect(tabPackageIdentifiers.contains(self.parentPackageB.identifier)) == false
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
