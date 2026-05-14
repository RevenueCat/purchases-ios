//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Combine
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallPackageSelectionCoordinatorTests: TestCase {

    private var cancellables: Set<AnyCancellable> = []

    @MainActor
    func testRootSelectionCommitsToPackageContextFromCommittedEvent() {
        let scope = Self.makeScope(paywallID: "paywall_a")
        let store = PaywallStateStore()
        let context = Self.makeContext(package: TestData.monthlyPackage)
        let coordinator = Self.makeCoordinator(scope: scope, store: store, context: context)
        let contextExpectation = self.expectation(description: "context updated from committed event")
        context.$package.dropFirst().sink { package in
            if package?.identifier == TestData.annualPackage.identifier {
                contextExpectation.fulfill()
            }
        }.store(in: &cancellables)

        coordinator.selectRootPackage(TestData.annualPackage)

        self.wait(for: [contextExpectation], timeout: 1)
        XCTAssertEqual(context.package?.identifier, TestData.annualPackage.identifier)
        XCTAssertEqual(
            store.value(for: .paywall(scope: scope, field: .rootSelectedPackageID)),
            .packageID(TestData.annualPackage.identifier)
        )
    }

    @MainActor
    func testRejectedRootSelectionDoesNotChangePackageContext() {
        let scope = Self.makeScope(paywallID: "paywall_a")
        let store = PaywallStateStore()
        let context = Self.makeContext(package: TestData.monthlyPackage)
        let coordinator = Self.makeCoordinator(
            scope: scope,
            store: store,
            context: context,
            mutationHandler: PaywallStateMutationHandler { proposal in
                proposal.reject()
            }
        )

        coordinator.selectRootPackage(TestData.annualPackage)

        XCTAssertEqual(context.package?.identifier, TestData.monthlyPackage.identifier)
        XCTAssertNil(store.value(for: .paywall(scope: scope, field: .rootSelectedPackageID)))
    }

    @MainActor
    func testReplacementRootSelectionUpdatesContextToReplacement() {
        let scope = Self.makeScope(paywallID: "paywall_a")
        let store = PaywallStateStore()
        let context = Self.makeContext(package: TestData.monthlyPackage)
        let contextExpectation = self.expectation(description: "context updated to replacement")
        context.$package.dropFirst().sink { package in
            if package?.identifier == TestData.weeklyPackage.identifier {
                contextExpectation.fulfill()
            }
        }.store(in: &cancellables)
        let coordinator = Self.makeCoordinator(
            scope: scope,
            store: store,
            context: context,
            mutationHandler: PaywallStateMutationHandler { proposal in
                proposal.replace(with: .init(
                    key: .paywall(scope: scope, field: .rootSelectedPackageID),
                    value: .packageID(TestData.weeklyPackage.identifier)
                ))
            }
        )

        coordinator.selectRootPackage(TestData.annualPackage)

        self.wait(for: [contextExpectation], timeout: 1)
        XCTAssertEqual(context.package?.identifier, TestData.weeklyPackage.identifier)
        XCTAssertEqual(
            store.value(for: .paywall(scope: scope, field: .rootSelectedPackageID)),
            .packageID(TestData.weeklyPackage.identifier)
        )
    }

    @MainActor
    func testSheetSelectionUpdatesWhileActiveAndDismissalClearsSheetSlotAndRestoresWorkflowPackage() {
        let scope = Self.makeScope(paywallID: "paywall_a")
        let sheetComponentID = "sheet_component"
        var currentWorkflowPackage: Package? = nil
        let store = PaywallStateStore()
        let context = Self.makeContext(package: TestData.monthlyPackage)
        let coordinator = Self.makeCoordinator(
            scope: scope,
            store: store,
            context: context,
            currentWorkflowSelectedPackage: { currentWorkflowPackage }
        )
        let sheetSelectionExpectation = self.expectation(description: "sheet selection updates context")
        let dismissalExpectation = self.expectation(description: "sheet dismissal restores context")
        context.$package.dropFirst().sink { package in
            switch package?.identifier {
            case TestData.annualPackage.identifier:
                sheetSelectionExpectation.fulfill()
            case TestData.weeklyPackage.identifier:
                dismissalExpectation.fulfill()
            default:
                break
            }
        }.store(in: &cancellables)

        coordinator.selectSheetPackage(TestData.annualPackage, componentID: sheetComponentID)

        self.wait(for: [sheetSelectionExpectation], timeout: 1)
        XCTAssertEqual(context.package?.identifier, TestData.annualPackage.identifier)

        currentWorkflowPackage = TestData.weeklyPackage
        coordinator.clearSheetSelection(componentID: sheetComponentID)

        self.wait(for: [dismissalExpectation], timeout: 1)
        XCTAssertEqual(context.package?.identifier, TestData.weeklyPackage.identifier)
        XCTAssertNil(store.value(for: .paywall(
            scope: scope,
            field: .sheetSelectedPackageID(componentID: sheetComponentID)
        )))
    }

    @MainActor
    func testCopiedPaywallInstancesWithSharedStoreAndIdenticalComponentIDsRemainIsolatedByScope() {
        let scopeA = Self.makeScope(paywallID: "paywall_a")
        let scopeB = Self.makeScope(paywallID: "paywall_b")
        let store = PaywallStateStore()
        let contextA = Self.makeContext(package: TestData.monthlyPackage)
        let contextB = Self.makeContext(package: TestData.monthlyPackage)
        let coordinatorA = Self.makeCoordinator(scope: scopeA, store: store, context: contextA)
        let coordinatorB = Self.makeCoordinator(scope: scopeB, store: store, context: contextB)
        let contextAExpectation = self.expectation(description: "first copy context updated")
        contextA.$package.dropFirst().sink { package in
            if package?.identifier == TestData.annualPackage.identifier {
                contextAExpectation.fulfill()
            }
        }.store(in: &cancellables)

        coordinatorA.selectRootPackage(TestData.annualPackage)

        self.wait(for: [contextAExpectation], timeout: 1)
        XCTAssertEqual(contextA.package?.identifier, TestData.annualPackage.identifier)
        XCTAssertEqual(contextB.package?.identifier, TestData.monthlyPackage.identifier)

        let contextBExpectation = self.expectation(description: "second copy context updated")
        contextB.$package.dropFirst().sink { package in
            if package?.identifier == TestData.weeklyPackage.identifier {
                contextBExpectation.fulfill()
            }
        }.store(in: &cancellables)

        coordinatorB.selectRootPackage(TestData.weeklyPackage)

        self.wait(for: [contextBExpectation], timeout: 1)
        XCTAssertEqual(contextA.package?.identifier, TestData.annualPackage.identifier)
        XCTAssertEqual(contextB.package?.identifier, TestData.weeklyPackage.identifier)
    }

    @MainActor
    private static func makeCoordinator(
        scope: PaywallStateScope,
        store: PaywallStateStore,
        context: PackageContext,
        mutationHandler: PaywallStateMutationHandler? = nil,
        currentWorkflowSelectedPackage: @escaping () -> Package? = { nil }
    ) -> PaywallPackageSelectionCoordinator {
        PaywallPackageSelectionCoordinator(
            scope: scope,
            store: store,
            mutationHandler: mutationHandler,
            packageContext: context,
            packages: [
                TestData.monthlyPackage,
                TestData.annualPackage,
                TestData.weeklyPackage
            ],
            defaultPackage: TestData.monthlyPackage,
            currentWorkflowSelectedPackage: currentWorkflowSelectedPackage
        )
    }

    @MainActor
    private static func makeContext(package: Package?) -> PackageContext {
        PackageContext(
            package: package,
            variableContext: .init(packages: [
                TestData.monthlyPackage,
                TestData.annualPackage,
                TestData.weeklyPackage
            ])
        )
    }

    private static func makeScope(paywallID: String) -> PaywallStateScope {
        PaywallStateScope(
            instanceID: UUID(),
            paywallID: paywallID,
            offeringIdentifier: "default",
            paywallRevision: 1,
            workflowPageID: nil
        )
    }

}

#endif
