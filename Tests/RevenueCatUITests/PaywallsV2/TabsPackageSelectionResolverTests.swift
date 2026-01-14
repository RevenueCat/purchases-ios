//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsPackageSelectionResolverTests.swift
//
//  Created by RevenueCat on 3/10/25.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class TabsPackageSelectionResolverTests: TestCase {

    private var parentPackageA: Package {
        Package(
            identifier: "parent_package_a",
            packageType: .custom,
            storeProduct: TestData.monthlyProduct.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    private var parentPackageB: Package {
        Package(
            identifier: "parent_package_b",
            packageType: .custom,
            storeProduct: TestData.annualProduct.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    private var tabPackageC: Package {
        Package(
            identifier: "tab_package_c",
            packageType: .custom,
            storeProduct: TestData.weeklyProduct.toStoreProduct(),
            offeringIdentifier: "test_offering",
            webCheckoutUrl: nil
        )
    }

    func testTabWithoutPackagesRestoresParentOwnedSelection() {
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )

        let plan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: self.parentPackageA,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: [],
            tabDefaultPackage: nil
        )

        expect(plan.parentUpdate?.package?.identifier) == self.parentPackageA.identifier
        expect(plan.parentUpdate?.variableContext.mostExpensivePricePerMonth)
            == parentOwnedVariableContext.mostExpensivePricePerMonth
        expect(plan.tabUpdate).to(beNil())
    }

    func testParentPackageInTabKeepsPackageButUsesTabVariableContext() {
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )
        let tabPackages = [self.parentPackageB, self.tabPackageC]
        let expectedTabVariableContext = PackageContext.VariableContext(packages: tabPackages)

        let plan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: self.parentPackageB,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: tabPackages,
            tabDefaultPackage: self.parentPackageB
        )

        expect(plan.tabUpdate?.package?.identifier) == self.parentPackageB.identifier
        expect(plan.parentUpdate?.package?.identifier) == self.parentPackageB.identifier
        expect(plan.tabUpdate?.variableContext.mostExpensivePricePerMonth)
            == expectedTabVariableContext.mostExpensivePricePerMonth
    }

    func testParentPackageNotInTabUsesTabDefault() {
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )
        let tabPackages = [self.tabPackageC]
        let expectedTabVariableContext = PackageContext.VariableContext(packages: tabPackages)

        let plan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: self.parentPackageA,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: tabPackages,
            tabDefaultPackage: self.tabPackageC
        )

        expect(plan.tabUpdate?.package?.identifier) == self.tabPackageC.identifier
        expect(plan.parentUpdate?.package?.identifier) == self.tabPackageC.identifier
        expect(plan.tabUpdate?.variableContext.mostExpensivePricePerMonth)
            == expectedTabVariableContext.mostExpensivePricePerMonth
    }

    func testTabWithPackagesAndNilDefaultYieldsNoUpdates() {
        let parentOwnedVariableContext = PackageContext.VariableContext(
            packages: [self.parentPackageA, self.parentPackageB]
        )
        let tabPackages = [self.tabPackageC]

        let plan = TabsPackageSelectionResolver.resolveTabSwitch(
            parentOwnedPackage: nil,
            parentOwnedVariableContext: parentOwnedVariableContext,
            parentCurrentVariableContext: parentOwnedVariableContext,
            tabPackages: tabPackages,
            tabDefaultPackage: nil
        )

        expect(plan.tabUpdate).to(beNil())
        expect(plan.parentUpdate).to(beNil())
    }
}

#endif
