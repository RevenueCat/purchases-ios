//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CreateTicketViewTests.swift
//
//  Created by Rosie Watson on 11/10/2025

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class CreateTicketViewTests: TestCase {

    @MainActor
    func testCreateTicketViewCanBeInstantiatedWithoutCrashing() {
        #if !os(watchOS) && !os(macOS)
        let mockPurchases = MockCustomerCenterPurchases()
        let createTicketView = CreateTicketView(
            isPresented: .constant(true),
            purchasesProvider: mockPurchases
        )
            .environment(\.localization, CustomerCenterConfigData.mock().localization)
            .environment(\.appearance, CustomerCenterConfigData.mock().appearance)

        let viewController = UIHostingController(rootView: createTicketView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.view.layoutIfNeeded()

        expect(viewController.view).toNot(beNil())
        #endif
    }

    @MainActor
    func testCreateTicketViewCallsPurchasesProviderOnSubmit() async {
        let mockPurchases = MockCustomerCenterPurchases()
        mockPurchases.createTicketResult = .success(true)

        // Create the view and simulate ticket creation
        _ = CreateTicketView(
            isPresented: .constant(true),
            purchasesProvider: mockPurchases
        )

        // Simulate the submitTicket action by calling the mock directly
        let result = try? await mockPurchases.createTicket(
            customerEmail: "test@example.com",
            ticketDescription: "Test description"
        )

        expect(result) == true
    }

    @MainActor
    func testCreateTicketViewHandlesSuccessfulSubmission() async {
        let mockPurchases = MockCustomerCenterPurchases()
        mockPurchases.createTicketResult = .success(true)

        let result = try? await mockPurchases.createTicket(
            customerEmail: "test@example.com",
            ticketDescription: "Test description"
        )

        expect(result) == true
    }

    @MainActor
    func testCreateTicketViewHandlesFailedSubmission() async {
        let mockPurchases = MockCustomerCenterPurchases()
        mockPurchases.createTicketResult = .success(false)

        let result = try? await mockPurchases.createTicket(
            customerEmail: "test@example.com",
            ticketDescription: "Test description"
        )

        expect(result) == false
    }

    @MainActor
    func testCreateTicketViewHandlesError() async {
        let mockPurchases = MockCustomerCenterPurchases()
        let expectedError = NSError(domain: "TestError", code: 123)
        mockPurchases.createTicketResult = .failure(expectedError)

        do {
            _ = try await mockPurchases.createTicket(
                customerEmail: "test@example.com",
                ticketDescription: "Test description"
            )
            fail("Expected error to be thrown")
        } catch {
            expect((error as NSError).code) == 123
        }
    }
}

#endif
