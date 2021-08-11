//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesOrchestrator.swift
//
//  Created by Andrés Boedo on 10/8/21.

import Foundation
import StoreKit

public typealias PurchaseCompletedBlock = (SKPaymentTransaction?, PurchaserInfo?, Error?, Bool) -> Void
public typealias RCDeferredPromotionalPurchaseBlock = (@escaping PurchaseCompletedBlock) -> Void

@objc(RCPurchasesOrchestratorDelegate) public protocol PurchasesOrchestratorDelegate {
    func shouldPurchasePromoProduct(_ product: SKProduct, defermentBlock: @escaping RCDeferredPromotionalPurchaseBlock)
}

// todo: make internal
@objc(RCPurchasesOrchestrator) public class PurchasesOrchestrator: NSObject {
    private var presentedOfferingIDsByProductID: [String: String] = [:]
    private var purchaseCompleteCallbacksByProductID: [String: PurchaseCompletedBlock] = [:]
    public var finishTransactions = false
    public var allowSharingAppStoreAccount = false

    private let productsManager: ProductsManager
    private let storeKitWrapper: StoreKitWrapper
    private let operationDispatcher: OperationDispatcher
    private let receiptFecher: ReceiptFetcher
    private let purchaserInfoManager: PurchaserInfoManager
    private let backend: Backend
    private let identityManager: IdentityManager

    private weak var maybeDelegate: PurchasesOrchestratorDelegate?

    // todo: remove explicit unwrap once nullability in identityManager is updated
    private var appUserID: String { identityManager.maybeCurrentAppUserID! }

    var unsyncedAttributesByKey: SubscriberAttributeDict {
        // todo
        // blocked on SubscriberAttributesManager migration
        return [:]
    }

    @objc public init(delegate: PurchasesOrchestratorDelegate,
                      productsManager: ProductsManager,
                      storeKitWrapper: StoreKitWrapper,
                      operationDispatcher: OperationDispatcher,
                      receiptFetcher: ReceiptFetcher,
                      purchaserInfoManager: PurchaserInfoManager,
                      backend: Backend,
                      identityManager: IdentityManager) {
        self.productsManager = productsManager
        self.maybeDelegate = delegate
        self.storeKitWrapper = storeKitWrapper
        self.operationDispatcher = operationDispatcher
        self.receiptFecher = receiptFetcher
        self.purchaserInfoManager = purchaserInfoManager
        self.backend = backend
        self.identityManager = identityManager
    }

    @objc public func syncPurchases(completion: @escaping (PurchaserInfo?, Error?) -> Void) {
        // todo
    }

}

extension PurchasesOrchestrator: StoreKitWrapperDelegate {

    public func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                                updatedTransaction transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .restored, // for observer mode
             .purchased:
            handlePurchasedTransaction(transaction)
        case .purchasing:
            break
        case .failed:
            handleFailedTransaction(transaction)
        case .deferred:
            handleDeferredTransaction(transaction)
        @unknown default:
            Logger.warn("unhandled transaction state!")
        }

    }

    public func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                                removedTransaction transaction: SKPaymentTransaction) {
        // todo: remove
        // unused for now
    }

    public func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                                shouldAddStorePayment payment: SKPayment,
                                for product: SKProduct) -> Bool {
        productsManager.cacheProduct(product)

        guard let delegate = maybeDelegate else { return false }
        delegate.shouldPurchasePromoProduct(product) { completion in
            self.purchaseCompleteCallbacksByProductID[product.productIdentifier] = completion
            storeKitWrapper.add(payment)
        }
        return false
    }

    public func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                                didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(String(format: Strings.purchase.entitlements_revoked_syncing_purchases, productIdentifiers))
        syncPurchases { _, _ in
            Logger.debug(Strings.purchase.purchases_synced)
        }
    }

}

// pragma: transaction state updates
private extension PurchasesOrchestrator {

    func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        receiptFecher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeReceiptData in
            if let receiptData = maybeReceiptData,
               !receiptData.isEmpty {
                self.fetchProductsAndPostReceipt(withTransaction: transaction, receiptData: receiptData)
            } else {
                self.handleReceiptPost(withTransaction: transaction,
                                       maybePurchaserInfo: nil,
                                       maybeSubscriberAttributes: nil,
                                       maybeError: ErrorUtils.missingReceiptFileError())
            }
        }
    }

    func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error,
           let completion = getAndRemovePurchaseCompletedCallback(forTransaction: transaction) {
            let nsError = error as NSError
            let userCancelled = nsError.code == SKError.paymentCancelled.rawValue
            operationDispatcher.dispatchOnMainThread {
                completion(transaction,
                           nil,
                           ErrorUtils.purchasesError(withSKError: error),
                           userCancelled)
            }
        }

        if finishTransactions {
            storeKitWrapper.finishTransaction(transaction)
        }
    }

    func handleDeferredTransaction(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error,
           let completion = getAndRemovePurchaseCompletedCallback(forTransaction: transaction) {
            let nsError = error as NSError
            let userCancelled = nsError.code == SKError.paymentCancelled.rawValue
            operationDispatcher.dispatchOnMainThread {
                completion(transaction, nil, ErrorUtils.paymentDeferredError(), userCancelled)
            }
        }
    }

}

private extension PurchasesOrchestrator {

    func getAndRemovePurchaseCompletedCallback(forTransaction transaction: SKPaymentTransaction) -> PurchaseCompletedBlock? {
        if let productIdentifier = transaction.rc_productIdentifier {
            let maybeCompletion = purchaseCompleteCallbacksByProductID.removeValue(forKey: productIdentifier)
            return maybeCompletion
        }
        return nil
    }

    func fetchProductsAndPostReceipt(withTransaction transaction: SKPaymentTransaction, receiptData: Data) {
        guard let productIdentifier = transaction.rc_productIdentifier else {
            self.handleReceiptPost(withTransaction: transaction,
                                   maybePurchaserInfo: nil,
                                   maybeSubscriberAttributes: nil,
                                   maybeError: ErrorUtils.unknownError())
            return
        }

        self.products(withIdentifiers: [productIdentifier]) { products in
            self.postReceipt(withTransaction: transaction, receiptData: receiptData, products: products)
        }
    }

    func postReceipt(withTransaction transaction: SKPaymentTransaction, receiptData: Data, products: Set<SKProduct>) {
        var maybeProductInfo: ProductInfo?
        var maybePresentedOfferingID: String?
        if let product = products.first {
            let productInfo = ProductInfoExtractor().extractInfo(from: product)
            let productID = productInfo.productIdentifier
            let presentedOfferingID = presentedOfferingIDsByProductID[productID]
            presentedOfferingIDsByProductID.removeValue(forKey: productID)
            maybeProductInfo = productInfo
            maybePresentedOfferingID = presentedOfferingID
        }
        let unsyncedAttributes = unsyncedAttributesByKey

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: allowSharingAppStoreAccount,
                     productInfo: maybeProductInfo,
                     presentedOfferingIdentifier: maybePresentedOfferingID,
                     observerMode: !finishTransactions,
                     subscriberAttributes: unsyncedAttributes) { maybePurchaserInfo, maybeError in
            self.handleReceiptPost(withTransaction: transaction,
                                   maybePurchaserInfo: maybePurchaserInfo,
                                   maybeSubscriberAttributes: unsyncedAttributes,
                                   maybeError: maybeError)
        }
    }

    func products(withIdentifiers identifiers: [String],
                  completion: @escaping (Set<SKProduct>) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        productsManager.products(withIdentifiers: productIdentifiersSet) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(products)
            }
        }
    }

    func handleReceiptPost(withTransaction transaction: SKPaymentTransaction,
                           maybePurchaserInfo: PurchaserInfo?,
                           maybeSubscriberAttributes: SubscriberAttributeDict?,
                           maybeError: Error?) {
        operationDispatcher.dispatchOnMainThread {
            let appUserID = self.appUserID
            self.markSyncedIfNeeded(subscriberAttributes: maybeSubscriberAttributes,
                                    appUserID: appUserID,
                                    maybeError: maybeError)

            let maybeCompletion = self.getAndRemovePurchaseCompletedCallback(forTransaction: transaction)
            if let purchaserInfo = maybePurchaserInfo {
                self.purchaserInfoManager.cache(purchaserInfo: purchaserInfo, appUserID: appUserID)

                if let completion = maybeCompletion {
                    completion(transaction, purchaserInfo, nil, false)
                }

                if self.finishTransactions {
                    self.storeKitWrapper.finishTransaction(transaction)
                }
            } else if let nsError = maybeError as NSError?,
                  let finishableValue = nsError.userInfo[ErrorDetails.finishableKey as String],
                  let finishableBool = (finishableValue as AnyObject).boolValue {
                if let completion = maybeCompletion {
                    completion(transaction, nil, nsError, false)
                }
                if finishableBool {
                    self.storeKitWrapper.finishTransaction(transaction)
                }
            } else {
                Logger.error(Strings.receipt.unknown_backend_error)
                if let completion = maybeCompletion,
                   let error = maybeError {
                    completion(transaction, nil, error, false)
                }
            }

        }
    }

    func markSyncedIfNeeded(subscriberAttributes: SubscriberAttributeDict?, appUserID: String, maybeError: Error?) {
        // todo
        // blocked on SubscriberAttributesManager migration
    }

}
