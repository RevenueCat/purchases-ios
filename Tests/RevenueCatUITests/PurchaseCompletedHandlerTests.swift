//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseCompletedHandlerTests.swift
//
//  Created by Nacho Soto on 7/31/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PurchaseCompletedHandlerTests: TestCase {

    func testOnPurchaseStarted() throws {
        var started = false
        var packageBeingPurchased: Package?

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onPurchaseStarted {
                started = true
            }
            .onPurchaseStarted { package in
                packageBeingPurchased = package
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(started).toEventually(beTrue())
        expect(packageBeingPurchased).toEventuallyNot(beNil())
    }

    func testOnPurchaseCompletedWithCancellation() throws {
        let handler: PurchaseHandler = .cancelling()

        var customerInfo: CustomerInfo?
        var purchased = false

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: handler
        )
            .onPurchaseCompleted {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await handler.purchase(package: Self.package)
            purchased = true
        }

        expect(purchased).toEventually(beTrue())
        expect(customerInfo).to(beNil())
    }

    func testOnPurchaseCompleted() throws {
        var customerInfo: CustomerInfo?

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onPurchaseCompleted {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testOnPurchaseCompletedWithTransaction() throws {
        var result: (transaction: StoreTransaction?, customerInfo: CustomerInfo)?

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onPurchaseCompleted { transaction, customerInfo in
                result = (transaction, customerInfo)
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
        }

        expect(result).toEventuallyNot(beNil())
        expect(result?.customerInfo) === TestData.customerInfo
        expect(result?.transaction).to(beNil())
    }

    func testOnPurchaseCancelled() throws {
        let handler: PurchaseHandler = .cancelling()

        var completed = false
        var cancelled = false

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: handler
        )
            .onPurchaseCancelled {
                cancelled = true
            }
            .addToHierarchy()

        Task {
            _ = try await handler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(cancelled) == true
    }

    func testOnPurchaseCancelledWithCompletion() throws {
        var completed = false
        var cancelled = false

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onPurchaseCancelled {
                cancelled = true
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.purchase(package: Self.package)
            completed = true
        }

        expect(completed).toEventually(beTrue())
        expect(cancelled) == false
    }

    func testOnPurchaseFailure() throws {
        var error: NSError?

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.failingHandler
        )
            .onPurchaseFailure {
                error = $0
            }
            .addToHierarchy()

        Task {
            _ = try? await Self.failingHandler.purchase(package: Self.package)
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    func testOnRestoreStarted() throws {
        var started = false

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onRestoreStarted {
                started = true
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.restorePurchases()
        }

        expect(started).toEventually(beTrue())
    }

    func testOnRestoreCompleted() throws {
        var customerInfo: CustomerInfo?

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.purchaseHandler
        )
            .onRestoreCompleted {
                customerInfo = $0
            }
            .addToHierarchy()

        Task {
            _ = try await Self.purchaseHandler.restorePurchases()
            // Simulates what `RestorePurchasesButton` does after dismissing the alert.
            Self.purchaseHandler.setRestored(TestData.customerInfo)
        }

        expect(customerInfo).toEventually(be(TestData.customerInfo))
    }

    func testOnRestoreFailure() throws {
        var error: NSError?

        _ = try PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: Self.failingHandler
        )
            .onRestoreFailure {
                error = $0
            }
            .addToHierarchy()

        Task {
            _ = try? await Self.failingHandler.restorePurchases()
        }

        expect(error).toEventually(matchError(Self.failureError))
    }

    private static let purchaseHandler: PurchaseHandler = .mock()
    private static let failingHandler: PurchaseHandler = .failing(failureError)
    private static let offering = TestData.offeringWithNoIntroOffer
    private static let package = TestData.annualPackage
    private static let failureError: Error = ErrorCode.storeProblemError

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallView {

    init(
        offering: Offering,
        customerInfo: CustomerInfo,
        introEligibility: TrialOrIntroEligibilityChecker,
        purchaseHandler: PurchaseHandler
    ) {
        self.init(
            configuration: .init(
                offering: offering,
                customerInfo: customerInfo,
                introEligibility: introEligibility,
                purchaseHandler: purchaseHandler
            )
        )
    }

}

#endif
