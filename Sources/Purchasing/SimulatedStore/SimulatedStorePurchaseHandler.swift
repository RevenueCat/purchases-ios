//
//  SimulatedStorePurchaseHandler.swift
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

protocol SimulatedStorePurchaseHandlerType: AnyObject, Sendable {

    @MainActor
    func purchase(product: TestStoreProduct) async -> TestPurchaseResult

}

/// The object that handles purchases in the Simulated Store.
///
/// This class is used to handle purchases when using a Simulated Store API key.
actor SimulatedStorePurchaseHandler: SimulatedStorePurchaseHandlerType {

    private let purchaseUI: SimulatedStorePurchaseUI
    private let dateProvider: DateProvider

    private var currentPurchaseTask: Task<TestPurchaseResult, Never>?
    private var purchaseInProgress: Bool {
        return self.currentPurchaseTask != nil
    }

    init(systemInfo: SystemInfo) {
        self.purchaseUI = DefaultSimulatedStorePurchaseUI(systemInfo: systemInfo)
        self.dateProvider = DateProvider()
    }

    // For testing purposes
    init(purchaseUI: SimulatedStorePurchaseUI, dateProvider: DateProvider) {
        self.purchaseUI = purchaseUI
        self.dateProvider = dateProvider
    }

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
                Logger.debug(Strings.purchase.simulating_purchase_success)
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
        let purchaseDate = self.dateProvider.now()
        let purchaseToken = "test_\(purchaseDate.millisecondsSince1970)_\(UUID().uuidString)"
        let storefront = await Storefront.currentStorefront
        let simulatedStoreTransaction = SimulatedStoreTransaction(productIdentifier: product.productIdentifier,
                                                                  purchaseDate: purchaseDate,
                                                                  transactionIdentifier: purchaseToken,
                                                                  storefront: storefront,
                                                                  jwsRepresentation: purchaseToken)
        return StoreTransaction(simulatedStoreTransaction)
    }

    nonisolated private var simulatedError: PurchasesError {
        return ErrorUtils.testStoreSimulatedPurchaseError()
    }

}

// MARK: - Purchase Alert Presentation

private extension SimulatedStorePurchaseHandler {

}
