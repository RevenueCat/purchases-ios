//
//  TestStorePurchaseHandler.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 16/7/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

enum TestPurchaseResult {
    case cancel
    case failure(PurchasesError)
    case success(StoreTransaction)
}

protocol TestStorePurchaseHandlerType: AnyObject, Sendable {

    #if TEST_STORE

    @MainActor
    func purchase(product: TestStoreProduct) async -> TestPurchaseResult

    #endif // TEST_STORE
}

/// The object that handles purchases in the Test Store.
///
/// This class is used to handle purchases when using a Test Store API key.
actor TestStorePurchaseHandler: TestStorePurchaseHandlerType {

    private let purchaseUI: TestStorePurchaseUI

    private var currentPurchaseTask: Task<TestPurchaseResult, Never>?
    private var purchaseInProgress: Bool {
        return self.currentPurchaseTask != nil
    }

    init(systemInfo: SystemInfo) {
        self.purchaseUI = DefaultTestStorePurchaseUI(systemInfo: systemInfo)
    }

    // For testing purposes
    init(purchaseUI: TestStorePurchaseUI) {
        self.purchaseUI = purchaseUI
    }

    #if TEST_STORE

    func purchase(product: TestStoreProduct) async -> TestPurchaseResult {
        guard !self.purchaseInProgress else {
            return .failure(ErrorUtils.operationAlreadyInProgressError())
        }

        let newPurchaseTask = Task<TestPurchaseResult, Never> { [weak self] in
            guard let self else {
                return .failure(ErrorUtils.unknownError())
            }

            let result = await self.purchaseUI.presentPurchaseUI(for: product)

            let purchaseResult: TestPurchaseResult
            switch result {
            case .cancel:
                purchaseResult = .cancel
            case .error(let error):
                purchaseResult = .failure(error)
            case .simulateFailure:
                purchaseResult = .failure(self.simulatedError)
            case .simulateSuccess:
                let transaction = await self.createStoreTransaction(product: product)
                purchaseResult = .success(transaction)
            }
            return purchaseResult
        }

        self.currentPurchaseTask = newPurchaseTask
        let purchaseResult = await newPurchaseTask.value
        self.currentPurchaseTask = nil

        return purchaseResult
    }

    private func createStoreTransaction(product: TestStoreProduct) async -> StoreTransaction {
        let purchaseDate = Date()
        let transactionId = "test_\(purchaseDate.millisecondsSince1970)_\(UUID().uuidString)"
        let storefront = await Storefront.currentStorefront
        let testStoreTransaction = TestStoreTransaction(productIdentifier: product.productIdentifier,
                                                        purchaseDate: purchaseDate,
                                                        transactionIdentifier: transactionId,
                                                        storefront: storefront,
                                                        jwsRepresentation: nil)
        return StoreTransaction(testStoreTransaction)
    }

    nonisolated private var simulatedError: PurchasesError {
        return ErrorUtils.productNotAvailableForPurchaseError(
            withMessage: Strings.purchase.error_message_for_simulating_test_purchase_failure.description)
    }

    #endif // TEST_STORE
}

// MARK: - Purchase Alert Presentation

private extension TestStorePurchaseHandler {

}
