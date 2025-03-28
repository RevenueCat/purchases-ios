//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsTracker.swift
//
//  Created by Cesar de la Vega on 4/4/24.

import Foundation

protocol DiagnosticsTrackerDelegate: AnyObject, Sendable {
    func onEventTracked() async throws
}

// swiftlint:disable function_parameter_count
// swiftlint:disable file_length
// swiftlint:disable type_body_length
protocol DiagnosticsTrackerType: Sendable {

    func setDelegate(_ delegate: DiagnosticsTrackerDelegate?)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func track(_ event: DiagnosticsEvent)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackCustomerInfoVerificationResultIfNeeded(_ customerInfo: CustomerInfo)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackProductsRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              requestedProductIds: Set<String>,
                              notFoundProductIds: Set<String>,
                              responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult,
                                   isRetry: Bool)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackPurchaseAttempt(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              productId: String,
                              promotionalOfferId: String?,
                              winBackOfferApplied: Bool,
                              purchaseResult: DiagnosticsEvent.PurchaseResult?,
                              responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackPurchaseIntentReceived(productId: String,
                                     offerId: String?,
                                     offerType: String?)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackMaxDiagnosticsSyncRetriesReached()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackClearingDiagnosticsAfterFailedSync()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackEnteredOfflineEntitlementsMode()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackErrorEnteringOfflineEntitlementsMode(reason: DiagnosticsEvent.OfflineEntitlementsModeErrorReason,
                                                   errorMessage: String)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackOfferingsStarted()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackOfferingsResult(requestedProductIds: Set<String>?,
                              notFoundProductIds: Set<String>?,
                              errorMessage: String?,
                              errorCode: Int?,
                              verificationResult: VerificationResult?,
                              cacheStatus: CacheStatus,
                              responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackProductsStarted(requestedProductIds: Set<String>)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackProductsResult(requestedProductIds: Set<String>,
                             notFoundProductIds: Set<String>?,
                             errorMessage: String?,
                             errorCode: Int?,
                             responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackGetCustomerInfoStarted()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackGetCustomerInfoResult(cacheFetchPolicy: CacheFetchPolicy,
                                    verificationResult: VerificationResult?,
                                    hadUnsyncedPurchasesBefore: Bool?,
                                    errorMessage: String?,
                                    errorCode: Int?,
                                    responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackPurchaseStarted(productId: String,
                              productType: StoreProduct.ProductType)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackPurchaseResult(productId: String,
                             productType: StoreProduct.ProductType,
                             verificationResult: VerificationResult?,
                             errorMessage: String?,
                             errorCode: Int?,
                             responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackSyncPurchasesStarted()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackSyncPurchasesResult(errorMessage: String?,
                                  errorCode: Int?,
                                  responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackRestorePurchasesStarted()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackRestorePurchasesResult(errorMessage: String?,
                                     errorCode: Int?,
                                     responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackApplePresentCodeRedemptionSheetRequest()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackAppleTrialOrIntroEligibilityRequest(storeKitVersion: StoreKitVersion,
                                                  requestedProductIds: Set<String>,
                                                  eligibilityUnknownCount: Int?,
                                                  eligibilityIneligibleCount: Int?,
                                                  eligibilityEligibleCount: Int?,
                                                  eligibilityNoIntroOfferCount: Int?,
                                                  errorMessage: String?,
                                                  errorCode: Int?,
                                                  responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackAppleTransactionQueueReceived(productId: String?,
                                            paymentDiscountId: String?,
                                            transactionState: String,
                                            errorMessage: String?)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackAppleTransactionUpdateReceived(transactionId: UInt64,
                                             environment: String?,
                                             storefront: String?,
                                             productId: String,
                                             purchaseDate: Date,
                                             expirationDate: Date?,
                                             price: Float?,
                                             currency: String?,
                                             reason: String?)
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor DiagnosticsTracker: DiagnosticsTrackerType {

    private let diagnosticsFileHandler: DiagnosticsFileHandlerType
    private let diagnosticsDispatcher: OperationDispatcher
    private let dateProvider: DateProvider
    private let appSessionID: UUID

    nonisolated func setDelegate(_ delegate: DiagnosticsTrackerDelegate?) {
        Task {
            await self.setDelegateInternal(delegate)
        }
    }

    private func setDelegateInternal(_ delegate: DiagnosticsTrackerDelegate?) {
        self.delegate = delegate
    }

    private weak var delegate: DiagnosticsTrackerDelegate? = nil

    init(diagnosticsFileHandler: DiagnosticsFileHandlerType,
         diagnosticsDispatcher: OperationDispatcher = .default,
         dateProvider: DateProvider = DateProvider(),
         appSessionID: UUID = SystemInfo.appSessionID) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
        self.diagnosticsDispatcher = diagnosticsDispatcher
        self.dateProvider = dateProvider
        self.appSessionID = appSessionID
    }

    nonisolated func track(_ event: DiagnosticsEvent) {
        self.diagnosticsDispatcher.dispatchOnWorkerThread {
            await self.clearDiagnosticsFileIfTooBig()
            await self.diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
            try? await self.delegate?.onEventTracked()
        }
    }

    nonisolated func trackCustomerInfoVerificationResultIfNeeded(
        _ customerInfo: CustomerInfo
    ) {
        let verificationResult = customerInfo.entitlements.verification
        if verificationResult == .notRequested {
            return
        }

        self.trackEvent(name: .customerInfoVerificationResult,
                        properties: DiagnosticsEvent.Properties(verificationResult: verificationResult.name))
    }

    nonisolated func trackProductsRequest(wasSuccessful: Bool,
                                          storeKitVersion: StoreKitVersion,
                                          errorMessage: String?,
                                          errorCode: Int?,
                                          storeKitErrorDescription: String?,
                                          requestedProductIds: Set<String>,
                                          notFoundProductIds: Set<String>,
                                          responseTime: TimeInterval) {
        self.trackEvent(name: .appleProductsRequest,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            storeKitVersion: storeKitVersion,
                            successful: wasSuccessful,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            skErrorDescription: storeKitErrorDescription,
                            requestedProductIds: requestedProductIds,
                            notFoundProductIds: notFoundProductIds
                        ))
    }

    nonisolated func trackHttpRequestPerformed(endpointName: String,
                                               responseTime: TimeInterval,
                                               wasSuccessful: Bool,
                                               responseCode: Int,
                                               backendErrorCode: Int?,
                                               resultOrigin: HTTPResponseOrigin?,
                                               verificationResult: VerificationResult,
                                               isRetry: Bool) {
        self.trackEvent(name: .httpRequestPerformed,
                        properties: DiagnosticsEvent.Properties(
                            verificationResult: verificationResult.name,
                            endpointName: endpointName,
                            responseTime: responseTime,
                            successful: wasSuccessful,
                            responseCode: responseCode,
                            backendErrorCode: backendErrorCode,
                            etagHit: resultOrigin == .cache,
                            isRetry: isRetry
                        ))
    }

    nonisolated func trackPurchaseAttempt(wasSuccessful: Bool,
                                          storeKitVersion: StoreKitVersion,
                                          errorMessage: String?,
                                          errorCode: Int?,
                                          storeKitErrorDescription: String?,
                                          productId: String,
                                          promotionalOfferId: String?,
                                          winBackOfferApplied: Bool,
                                          purchaseResult: DiagnosticsEvent.PurchaseResult?,
                                          responseTime: TimeInterval) {
        self.trackEvent(name: .applePurchaseAttempt,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            storeKitVersion: storeKitVersion,
                            successful: wasSuccessful,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            skErrorDescription: storeKitErrorDescription,
                            productId: productId,
                            promotionalOfferId: promotionalOfferId,
                            winBackOfferApplied: winBackOfferApplied,
                            purchaseResult: purchaseResult
                        ))
    }

    nonisolated func trackPurchaseIntentReceived(productId: String,
                                                 offerId: String?,
                                                 offerType: String?) {
        self.trackEvent(name: .applePurchaseIntentReceived,
                        properties: DiagnosticsEvent.Properties(
                            productId: productId,
                            offerId: offerId,
                            offerType: offerType
                        ))
    }

    nonisolated func trackMaxDiagnosticsSyncRetriesReached() {
        self.trackEvent(name: .maxEventsStoredLimitReached, properties: .empty)
    }

    nonisolated func trackClearingDiagnosticsAfterFailedSync() {
        self.trackEvent(name: .clearingDiagnosticsAfterFailedSync, properties: .empty)
    }

    nonisolated func trackEnteredOfflineEntitlementsMode() {
        self.trackEvent(name: .enteredOfflineEntitlementsMode, properties: .empty)
    }

    nonisolated func trackErrorEnteringOfflineEntitlementsMode(reason: DiagnosticsEvent.OfflineEntitlementsModeErrorReason,
                                                               errorMessage: String) {
        self.trackEvent(name: .errorEnteringOfflineEntitlementsMode,
                        properties: DiagnosticsEvent.Properties(
                            offlineEntitlementErrorReason: reason,
                            errorMessage: errorMessage
                        ))
    }

    nonisolated func trackOfferingsStarted() {
        self.trackEvent(name: .getOfferingsStarted, properties: .empty)
    }

    nonisolated func trackOfferingsResult(requestedProductIds: Set<String>?,
                                          notFoundProductIds: Set<String>?,
                                          errorMessage: String?,
                                          errorCode: Int?,
                                          verificationResult: VerificationResult?,
                                          cacheStatus: CacheStatus,
                                          responseTime: TimeInterval) {
        self.trackEvent(name: .getOfferingsResult,
                        properties: DiagnosticsEvent.Properties(
                            verificationResult: verificationResult?.name,
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            requestedProductIds: requestedProductIds,
                            notFoundProductIds: notFoundProductIds,
                            cacheStatus: cacheStatus
                        ))
    }

    nonisolated func trackProductsStarted(requestedProductIds: Set<String>) {
        self.trackEvent(name: .getProductsResult,
                        properties: DiagnosticsEvent.Properties(
                            requestedProductIds: requestedProductIds
                        ))
    }

    nonisolated func trackProductsResult(requestedProductIds: Set<String>,
                                         notFoundProductIds: Set<String>?,
                                         errorMessage: String?,
                                         errorCode: Int?,
                                         responseTime: TimeInterval) {
        self.trackEvent(name: .getProductsResult,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            requestedProductIds: requestedProductIds,
                            notFoundProductIds: notFoundProductIds
                        ))
    }

    nonisolated func trackGetCustomerInfoStarted() {
        self.trackEvent(name: .getCustomerInfoStarted, properties: .empty)
    }

    nonisolated func trackGetCustomerInfoResult(cacheFetchPolicy: CacheFetchPolicy,
                                                verificationResult: VerificationResult?,
                                                hadUnsyncedPurchasesBefore: Bool?,
                                                errorMessage: String?,
                                                errorCode: Int?,
                                                responseTime: TimeInterval) {
        self.trackEvent(name: .getCustomerInfoResult,
                        properties: DiagnosticsEvent.Properties(
                            verificationResult: verificationResult?.name,
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            cacheFetchPolicy: cacheFetchPolicy,
                            hadUnsyncedPurchasesBefore: hadUnsyncedPurchasesBefore
                        ))
    }

    nonisolated func trackSyncPurchasesStarted() {
        self.trackEvent(name: .syncPurchasesStarted, properties: .empty)
    }

    nonisolated func trackSyncPurchasesResult(errorMessage: String?,
                                              errorCode: Int?,
                                              responseTime: TimeInterval) {
        self.trackEvent(name: .syncPurchasesResult,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode
                        ))
    }

    nonisolated func trackRestorePurchasesStarted() {
        self.trackEvent(name: .restorePurchasesStarted, properties: .empty)
    }

    nonisolated func trackRestorePurchasesResult(errorMessage: String?,
                                                 errorCode: Int?,
                                                 responseTime: TimeInterval) {
        self.trackEvent(name: .restorePurchasesResult,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode
                        ))
    }

    nonisolated func trackPurchaseStarted(productId: String,
                                          productType: StoreProduct.ProductType) {
        self.trackEvent(name: .purchaseStarted,
                        properties: DiagnosticsEvent.Properties(
                            productId: productId,
                            productType: productType
                        )
        )
    }

    nonisolated func trackPurchaseResult(productId: String,
                                         productType: StoreProduct.ProductType,
                                         verificationResult: VerificationResult?,
                                         errorMessage: String?,
                                         errorCode: Int?,
                                         responseTime: TimeInterval) {
        self.trackEvent(name: .purchaseResult,
                        properties: DiagnosticsEvent.Properties(
                            verificationResult: verificationResult?.name,
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            productId: productId,
                            productType: productType
                        )
        )
    }

    nonisolated func trackApplePresentCodeRedemptionSheetRequest() {
        self.trackEvent(name: .applePresentCodeRedemptionSheetRequest, properties: .empty)
    }

    nonisolated func trackAppleTransactionUpdateReceived(transactionId: UInt64,
                                                         environment: String?,
                                                         storefront: String?,
                                                         productId: String,
                                                         purchaseDate: Date,
                                                         expirationDate: Date?,
                                                         price: Float?,
                                                         currency: String?,
                                                         reason: String?) {
        self.trackEvent(name: .appleTransactionUpdateReceived,
                        properties: DiagnosticsEvent.Properties(
                            productId: productId,
                            transactionId: transactionId,
                            environment: environment,
                            storefront: storefront,
                            purchaseDate: purchaseDate,
                            expirationDate: expirationDate,
                            price: price,
                            currency: currency,
                            reason: reason
                        ))
    }

    nonisolated func trackAppleTrialOrIntroEligibilityRequest(storeKitVersion: StoreKitVersion,
                                                              requestedProductIds: Set<String>,
                                                              eligibilityUnknownCount: Int?,
                                                              eligibilityIneligibleCount: Int?,
                                                              eligibilityEligibleCount: Int?,
                                                              eligibilityNoIntroOfferCount: Int?,
                                                              errorMessage: String?,
                                                              errorCode: Int?,
                                                              responseTime: TimeInterval) {
        self.trackEvent(name: .appleTrialOrIntroEligibilityRequest,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            storeKitVersion: storeKitVersion,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            requestedProductIds: requestedProductIds,
                            eligibilityUnknownCount: eligibilityUnknownCount,
                            eligibilityIneligibleCount: eligibilityIneligibleCount,
                            eligibilityEligibleCount: eligibilityEligibleCount,
                            eligibilityNoIntroOfferCount: eligibilityNoIntroOfferCount
                        ))
    }

    nonisolated func trackAppleTransactionQueueReceived(productId: String?,
                                                        paymentDiscountId: String?,
                                                        transactionState: String,
                                                        errorMessage: String?) {
        self.trackEvent(name: .appleTransactionQueueReceived,
                        properties: DiagnosticsEvent.Properties(
                            errorMessage: errorMessage,
                            skErrorDescription: transactionState,
                            productId: productId,
                            promotionalOfferId: paymentDiscountId
                        ))
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension DiagnosticsTracker {

    nonisolated  func trackEvent(name: DiagnosticsEvent.EventName, properties: DiagnosticsEvent.Properties) {
        self.track(
            DiagnosticsEvent(name: name,
                             properties: properties,
                             timestamp: self.dateProvider.now(),
                             appSessionId: self.appSessionID)
        )
    }

    func clearDiagnosticsFileIfTooBig() async {
        if await self.diagnosticsFileHandler.isDiagnosticsFileTooBig() {
            await self.diagnosticsFileHandler.emptyDiagnosticsFile()
            let maxEventsStoredEvent = DiagnosticsEvent(name: .maxEventsStoredLimitReached,
                                                        properties: .empty,
                                                        timestamp: self.dateProvider.now(),
                                                        appSessionId: self.appSessionID)
            await self.diagnosticsFileHandler.appendEvent(diagnosticsEvent: maxEventsStoredEvent)
        }
    }

}
