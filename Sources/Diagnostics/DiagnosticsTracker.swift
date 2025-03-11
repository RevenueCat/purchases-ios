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

// swiftlint:disable function_parameter_count
protocol DiagnosticsTrackerType {

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
    func trackPurchaseRequest(wasSuccessful: Bool,
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
    func trackMaxDiagnosticsSyncRetriesReached()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackClearingDiagnosticsAfterFailedSync()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackEnteredOfflineEntitlementsMode()

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackErrorEnteringOfflineEntitlementsMode(errorReason: String,
                                                   errorMessage: String)
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: DiagnosticsTrackerType, Sendable {

    private let diagnosticsFileHandler: DiagnosticsFileHandlerType
    private let diagnosticsDispatcher: OperationDispatcher
    private let dateProvider: DateProvider
    private let appSessionID: UUID

    init(diagnosticsFileHandler: DiagnosticsFileHandlerType,
         diagnosticsDispatcher: OperationDispatcher = .default,
         dateProvider: DateProvider = DateProvider(),
         appSessionID: UUID = SystemInfo.appSessionID) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
        self.diagnosticsDispatcher = diagnosticsDispatcher
        self.dateProvider = dateProvider
        self.appSessionID = appSessionID
    }

    func track(_ event: DiagnosticsEvent) {
        self.diagnosticsDispatcher.dispatchOnWorkerThread {
            await self.clearDiagnosticsFileIfTooBig()
            await self.diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
        }
    }

    func trackCustomerInfoVerificationResultIfNeeded(
        _ customerInfo: CustomerInfo
    ) {
        let verificationResult = customerInfo.entitlements.verification
        if verificationResult == .notRequested {
            return
        }

        let event = DiagnosticsEvent(
            name: .customerInfoVerificationResult,
            properties: DiagnosticsEvent.Properties(verificationResult: verificationResult.name),
            timestamp: self.dateProvider.now(),
            appSessionId: self.appSessionID
        )
        self.track(event)
    }

    func trackProductsRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              requestedProductIds: Set<String>,
                              notFoundProductIds: Set<String>,
                              responseTime: TimeInterval) {
        self.track(
            DiagnosticsEvent(name: .appleProductsRequest,
                             properties: DiagnosticsEvent.Properties(
                                responseTime: responseTime,
                                storeKitVersion: storeKitVersion,
                                successful: wasSuccessful,
                                errorMessage: errorMessage,
                                errorCode: errorCode,
                                skErrorDescription: storeKitErrorDescription,
                                requestedProductIds: requestedProductIds,
                                notFoundProductIds: notFoundProductIds
                             ),
                             timestamp: self.dateProvider.now(),
                             appSessionId: self.appSessionID)
        )
    }

    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult,
                                   isRetry: Bool) {
        self.track(
            DiagnosticsEvent(
                name: .httpRequestPerformed,
                properties: DiagnosticsEvent.Properties(
                    verificationResult: verificationResult.name,
                    endpointName: endpointName,
                    responseTime: responseTime,
                    successful: wasSuccessful,
                    responseCode: responseCode,
                    backendErrorCode: backendErrorCode,
                    etagHit: resultOrigin == .cache,
                    isRetry: isRetry
                ),
                timestamp: self.dateProvider.now(),
                appSessionId: self.appSessionID
            )
        )
    }

    func trackPurchaseRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              productId: String,
                              promotionalOfferId: String?,
                              winBackOfferApplied: Bool,
                              purchaseResult: DiagnosticsEvent.PurchaseResult?,
                              responseTime: TimeInterval) {
        self.track(
            DiagnosticsEvent(name: .applePurchaseAttempt,
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
                             ),
                             timestamp: self.dateProvider.now(),
                             appSessionId: self.appSessionID)
        )
    }

    func trackMaxDiagnosticsSyncRetriesReached() {
        self.track(DiagnosticsEvent(name: .maxEventsStoredLimitReached,
                                    properties: .empty,
                                    timestamp: self.dateProvider.now(),
                                    appSessionId: self.appSessionID))
    }

    func trackClearingDiagnosticsAfterFailedSync() {
        self.track(DiagnosticsEvent(name: .clearingDiagnosticsAfterFailedSync,
                                    properties: .empty,
                                    timestamp: self.dateProvider.now(),
                                    appSessionId: self.appSessionID))
    }

    func trackEnteredOfflineEntitlementsMode() {
        self.track(DiagnosticsEvent(name: .enteredOfflineEntitlementsMode,
                                    properties: .empty,
                                    timestamp: self.dateProvider.now(),
                                    appSessionId: self.appSessionID))
    }

    func trackErrorEnteringOfflineEntitlementsMode(errorReason: String,
                                                   errorMessage: String) {
        self.track(DiagnosticsEvent(name: .errorEnteringOfflineEntitlementsMode,
                                    properties: DiagnosticsEvent.Properties(
                                        offlineEntitlementErrorReason: errorReason,
                                        errorMessage: errorMessage
                                    ),
                                    timestamp: self.dateProvider.now(),
                                    appSessionId: self.appSessionID))
    }
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension DiagnosticsTracker {

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
