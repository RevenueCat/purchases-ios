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
    @objc public var finishTransactions = false
    @objc public var allowSharingAppStoreAccount: Bool {
        get {
            if let allow = _allowSharingAppStoreAccount {
                return allow
            } else {
                return identityManager.currentUserIsAnonymous
            }
        }
        set {
            _allowSharingAppStoreAccount = newValue
        }
    }

    private var _allowSharingAppStoreAccount: Bool?

    private var presentedOfferingIDsByProductID: [String: String] = [:]
    private var purchaseCompleteCallbacksByProductID: [String: PurchaseCompletedBlock] = [:]

    private let productsManager: ProductsManager
    private let storeKitWrapper: StoreKitWrapper
    private let operationDispatcher: OperationDispatcher
    private let receiptFetcher: ReceiptFetcher
    private let purchaserInfoManager: PurchaserInfoManager
    private let backend: Backend
    private let identityManager: IdentityManager
    private let receiptParser: ReceiptParser
    private let deviceCache: DeviceCache

    @objc public weak var maybeDelegate: PurchasesOrchestratorDelegate?

    // todo: remove explicit unwrap once nullability in identityManager is updated
    private var appUserID: String { identityManager.maybeCurrentAppUserID! }

    var unsyncedAttributesByKey: SubscriberAttributeDict {
        // todo
        // blocked on SubscriberAttributesManager migration
        return [:]
    }

    @objc public init(productsManager: ProductsManager,
                      storeKitWrapper: StoreKitWrapper,
                      operationDispatcher: OperationDispatcher,
                      receiptFetcher: ReceiptFetcher,
                      purchaserInfoManager: PurchaserInfoManager,
                      backend: Backend,
                      identityManager: IdentityManager,
                      receiptParser: ReceiptParser,
                      deviceCache: DeviceCache) {
        self.productsManager = productsManager
        self.storeKitWrapper = storeKitWrapper
        self.operationDispatcher = operationDispatcher
        self.receiptFetcher = receiptFetcher
        self.purchaserInfoManager = purchaserInfoManager
        self.backend = backend
        self.identityManager = identityManager
        self.receiptParser = receiptParser
        self.deviceCache = deviceCache
    }

    @objc public func restoreTransactions(completion maybeCompletion: ((PurchaserInfo?, Error?) -> Void)?) {
        syncPurchases(receiptRefreshPolicy: .always, isRestore: true, maybeCompletion: maybeCompletion)
    }

    @objc public func syncPurchases(completion maybeCompletion: ((PurchaserInfo?, Error?) -> Void)?) {
        syncPurchases(receiptRefreshPolicy: .never,
                      isRestore: allowSharingAppStoreAccount,
                      maybeCompletion: maybeCompletion)
    }

    @objc public func products(withIdentifiers identifiers: [String],
                               completion: @escaping ([SKProduct]) -> Void) {
        let productIdentifiersSet = Set(identifiers)
        guard !productIdentifiersSet.isEmpty else {
            operationDispatcher.dispatchOnMainThread { completion([]) }
            return
        }

        productsManager.products(withIdentifiers: productIdentifiersSet) { products in
            self.operationDispatcher.dispatchOnMainThread {
                completion(Array(products))
            }
        }
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    @objc public func paymentDiscount(forProductDiscount productDiscount: SKProductDiscount,
                                      product: SKProduct,
                                      completion: @escaping (SKPaymentDiscount?, Error?) -> Void) {
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeReceiptData in
            guard let receiptData = maybeReceiptData,
                  !receiptData.isEmpty else {
                      completion(nil, ErrorUtils.missingReceiptFileError())
                      return
                  }
            guard let discountIdentifier = productDiscount.identifier,
                  let subscriptionGroupIdentifier = product.subscriptionGroupIdentifier else {
                      // todo: replace with custom exception
                      completion(nil, ErrorUtils.unexpectedBackendResponseError())
                      return
                  }
            self.backend.post(offerIdForSigning: discountIdentifier,
                              productIdentifier: product.productIdentifier,
                              subscriptionGroup: subscriptionGroupIdentifier,
                              receiptData: receiptData,
                              appUserID: self.appUserID) { maybeSignature, maybeKeyIdentifier, maybeNonce, maybeTimestamp, maybeError in
                if let error = maybeError {
                    // todo: replace with custom exception
                    completion(nil, error)
                    return
                }

                guard let keyIdentifier = maybeKeyIdentifier,
                      let nonce = maybeNonce,
                      let signature = maybeSignature,
                      let timestamp = maybeTimestamp else {
                          // todo: replace with custom exception
                          completion(nil, ErrorUtils.unexpectedBackendResponseError())
                          return
                      }

                let paymentDiscount = SKPaymentDiscount(identifier: discountIdentifier,
                                                        keyIdentifier: keyIdentifier,
                                                        nonce: nonce,
                                                        signature: signature,
                                                        timestamp: timestamp)
                completion(paymentDiscount, nil)
            }
        }
    }

    @objc public func purchase(product: SKProduct,
                               payment: SKMutablePayment,
                               presentedOfferingIdentifier maybePresentedOfferingIdentifier: String?,
                               completion: @escaping PurchaseCompletedBlock) {
        Logger.debug("makePurchase")
        guard let productIdentifier = extractProductIdentifier(fromProduct: product, orPayment: payment) else {
            Logger.info(Strings.purchase.could_not_purchase_product_id_not_found)
            let errorMessage = "There was a problem purchasing the product: productIdentifier was nil"
            completion(nil,
                       nil,
                       ErrorUtils.unknownError(message: errorMessage),
                       false)
            return
        }

        if !self.finishTransactions {
            Logger.warn(Strings.purchase.purchasing_with_observer_mode_and_finish_transactions_false_warning)
        }

        let currentAppUserID = self.appUserID
        payment.applicationUsername = currentAppUserID

        preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: appUserID)

        if let presentedOfferingIdentifier = maybePresentedOfferingIdentifier {
            Logger.purchase(String(format: Strings.purchase.purchasing_product_from_package,
                                   productIdentifier,
                                   presentedOfferingIdentifier))
            // todo: concurrency handling
            presentedOfferingIDsByProductID[productIdentifier] = presentedOfferingIdentifier

        } else {
            Logger.purchase(String(format: Strings.purchase.purchasing_product, productIdentifier))
        }

        productsManager.cacheProduct(product)

        // todo: concurrency handling
        guard purchaseCompleteCallbacksByProductID[productIdentifier] == nil else {
            completion(nil, nil, ErrorUtils.operationAlreadyInProgressError(), false)
            return
        }
        purchaseCompleteCallbacksByProductID[productIdentifier] = completion
        storeKitWrapper.add(payment)
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
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeReceiptData in
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
            self.postReceipt(withTransaction: transaction,
                             receiptData: receiptData,
                             products: Set(products))
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

    func syncPurchases(receiptRefreshPolicy: ReceiptRefreshPolicy,
                       isRestore: Bool,
                       maybeCompletion: ((PurchaserInfo?, Error?) -> Void)?) {
        if !self.allowSharingAppStoreAccount {
            Logger.warn(Strings.restore.restoretransactions_called_with_allow_sharing_appstore_account_false_warning)
        }

        let currentAppUserID = self.appUserID
        // Refresh the receipt and post to backend, this will allow the transactions to be transferred.
        // https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
        receiptFetcher.receiptData(refreshPolicy: receiptRefreshPolicy) { maybeReceiptData in
            guard let receiptData = maybeReceiptData,
                  !receiptData.isEmpty else {
                      if SystemInfo.isSandbox {
                          Logger.appleWarning(Strings.receipt.no_sandbox_receipt_restore)
                      }

                      if let completion = maybeCompletion {
                          completion(nil, ErrorUtils.missingReceiptFileError())
                      }
                      return
                  }

            let maybeCachedPurchaserInfo = self.purchaserInfoManager.cachedPurchaserInfo(appUserID: currentAppUserID)
            let hasOriginalPurchaseDate = maybeCachedPurchaserInfo != nil
                                          && maybeCachedPurchaserInfo!.originalPurchaseDate != nil

            let receiptHasTransactions = self.receiptParser.receiptHasTransactions(receiptData: receiptData)

            if !receiptHasTransactions && hasOriginalPurchaseDate {
                if let completion = maybeCompletion {
                    self.operationDispatcher.dispatchOnMainThread {
                        completion(maybeCachedPurchaserInfo, nil)
                    }
                }
                return
            }

            let unsyncedAttributes = self.unsyncedAttributesByKey

            self.backend.post(receiptData: receiptData,
                              appUserID: currentAppUserID,
                              isRestore: isRestore,
                              productInfo: nil,
                              presentedOfferingIdentifier: nil,
                              observerMode: !self.finishTransactions,
                              subscriberAttributes: unsyncedAttributes) { maybePurchaserInfo, maybeError in
                self.handleReceiptPost(withPurchaserInfo: maybePurchaserInfo,
                                       error: maybeError,
                                       subscriberAttributes: unsyncedAttributes,
                                       completion: maybeCompletion)
            }
        }
    }

    func handleReceiptPost(withPurchaserInfo maybePurchaserInfo: PurchaserInfo?,
                           error maybeError: Error?,
                           subscriberAttributes: SubscriberAttributeDict,
                           completion maybeCompletion: ReceivePurchaserInfoBlock?) {
        operationDispatcher.dispatchOnMainThread {
            if let purchaserInfo = maybePurchaserInfo {
                self.purchaserInfoManager.cache(purchaserInfo: purchaserInfo, appUserID: self.appUserID)
            }

            self.markSyncedIfNeeded(subscriberAttributes: subscriberAttributes,
                                    appUserID: self.appUserID,
                                    maybeError: maybeError)

            if let completion = maybeCompletion {
                self.operationDispatcher.dispatchOnMainThread {
                    completion(maybePurchaserInfo, maybeError)
                }
            }
        }
    }

    // Although both SKProduct.productIdentifier and SKPayment.productIdentifier
    // are supposed to be non-null, we've seen instances where this is not true.
    // so we cast into optionals in order to check nullability, and try to fall back if possible.
    func extractProductIdentifier(fromProduct product: SKProduct, orPayment payment: SKPayment) -> String? {
        if let identifierFromProduct = product.productIdentifier as String? {
            return identifierFromProduct
        }
        Logger.appleWarning("product.productIdentifier is nil")

        if let identifierFromPayment = payment.productIdentifier as String? {
            return identifierFromPayment
        }
        Logger.appleWarning("payment.productIdentifier is nil")

        return nil
    }

    func preventPurchasePopupCallFromTriggeringCacheRefresh(appUserID: String) {
        deviceCache.setCacheTimestampToNowToPreventConcurrentPurchaserInfoUpdates(appUserID: appUserID)
        deviceCache.setOfferingsCacheTimestampToNow()
    }
}

// swiftlint:disable:this file_length
