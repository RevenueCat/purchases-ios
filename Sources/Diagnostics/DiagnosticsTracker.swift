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

protocol DiagnosticsTrackerType {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func track(_ event: DiagnosticsTracker.Event)

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: Sendable, DiagnosticsTrackerType {

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

    func track(_ event: DiagnosticsTracker.Event) {
        guard let (name, properties) = event.diagnosticsEvent else {
            return
        }

        let diagnosticsEvent = DiagnosticsEvent(name: name,
                                                properties: properties,
                                                timestamp: self.dateProvider.now(),
                                                appSessionId: self.appSessionID)
        self.diagnosticsDispatcher.dispatchOnWorkerThread {
            await self.clearDiagnosticsFileIfTooBig()
            await self.diagnosticsFileHandler.appendEvent(diagnosticsEvent: diagnosticsEvent)
        }
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

// MARK: - DiagnosticsTracker.Event

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension DiagnosticsTracker {

    enum Event: Equatable {
        case customerInfoVerification(result: VerificationResult)

        case productsRequest(wasSuccessful: Bool,
                             storeKitVersion: StoreKitVersion,
                             errorMessage: String?,
                             errorCode: Int?,
                             storeKitErrorDescription: String?,
                             requestedProductIds: Set<String>,
                             notFoundProductIds: Set<String>,
                             responseTime: TimeInterval)

        case httpRequestPerformed(endpointName: String,
                                  responseTime: TimeInterval,
                                  wasSuccessful: Bool,
                                  responseCode: Int,
                                  backendErrorCode: Int?,
                                  resultOrigin: HTTPResponseOrigin?,
                                  verificationResult: VerificationResult,
                                  isRetry: Bool)

        case purchaseRequest(wasSuccessful: Bool,
                             storeKitVersion: StoreKitVersion,
                             errorMessage: String?,
                             errorCode: Int?,
                             storeKitErrorDescription: String?,
                             productId: String,
                             promotionalOfferId: String?,
                             winBackOfferApplied: Bool,
                             purchaseResult: DiagnosticsEvent.PurchaseResult?,
                             responseTime: TimeInterval)

        case maxDiagnosticsSyncRetriesReached

        case clearingDiagnosticsAfterFailedSync

        case enteredOfflineEntitlementsMode

        case errorEnteringOfflineEntitlementsMode(reason: DiagnosticsEvent.OfflineEntitlementsModeErrorReason,
                                                  errorMessage: String)

        case offeringsStarted

        case offeringsResult(requestedProductIds: Set<String>?,
                             notFoundProductIds: Set<String>?,
                             errorMessage: String?,
                             errorCode: Int?,
                             verificationResult: VerificationResult?,
                             cacheStatus: CacheStatus,
                             responseTime: TimeInterval)

        case productsStarted(requestedProductIds: Set<String>)

        case productsResult(requestedProductIds: Set<String>,
                            notFoundProductIds: Set<String>?,
                            errorMessage: String?,
                            errorCode: Int?,
                            responseTime: TimeInterval)

        case getCustomerInfoStarted

        case getCustomerInfoResult(cacheFetchPolicy: CacheFetchPolicy,
                                   verificationResult: VerificationResult?,
                                   hadUnsyncedPurchasesBefore: Bool?,
                                   errorMessage: String?,
                                   errorCode: Int?,
                                   responseTime: TimeInterval)

        case syncPurchasesStarted

        case syncPurchasesResult(errorMessage: String?,
                                 errorCode: Int?,
                                 responseTime: TimeInterval)

        case restorePurchasesStarted

        case restorePurchasesResult(errorMessage: String?,
                                    errorCode: Int?,
                                    responseTime: TimeInterval)

        var diagnosticsEvent: (name: DiagnosticsEvent.EventName, properties: DiagnosticsEvent.Properties)? {
            switch self {
            case .customerInfoVerification(let verificationResult):
                if verificationResult == .notRequested {
                    return nil
                } else {
                    return (name: .customerInfoVerificationResult,
                            properties: DiagnosticsEvent.Properties(verificationResult: verificationResult.name))

                }
            case .productsRequest(let wasSuccessful,
                                  let storeKitVersion,
                                  let errorMessage,
                                  let errorCode,
                                  let storeKitErrorDescription,
                                  let requestedProductIds,
                                  let notFoundProductIds,
                                  let responseTime):
                return (name: .appleProductsRequest,
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
            case .httpRequestPerformed(let endpointName,
                                       let responseTime,
                                       let wasSuccessful,
                                       let responseCode,
                                       let backendErrorCode,
                                       let resultOrigin,
                                       let verificationResult,
                                       let isRetry):
                return (name: .httpRequestPerformed,
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
            case .purchaseRequest(let wasSuccessful,
                                  let storeKitVersion,
                                  let errorMessage,
                                  let errorCode,
                                  let storeKitErrorDescription,
                                  let productId,
                                  let promotionalOfferId,
                                  let winBackOfferApplied,
                                  let purchaseResult,
                                  let responseTime):
                return (name: .applePurchaseAttempt,
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
            case .maxDiagnosticsSyncRetriesReached:
                return (name: .maxEventsStoredLimitReached, properties: .empty)
            case .clearingDiagnosticsAfterFailedSync:
                return (name: .clearingDiagnosticsAfterFailedSync, properties: .empty)
            case .enteredOfflineEntitlementsMode:
                return (name: .enteredOfflineEntitlementsMode, properties: .empty)
            case .errorEnteringOfflineEntitlementsMode(let reason, let errorMessage):
                return (name: .errorEnteringOfflineEntitlementsMode,
                        properties: DiagnosticsEvent.Properties(
                            offlineEntitlementErrorReason: reason,
                            errorMessage: errorMessage
                        ))
            case .offeringsStarted:
                return (name: .getOfferingsStarted, properties: .empty)
            case .offeringsResult(let requestedProductIds,
                                  let notFoundProductIds,
                                  let errorMessage,
                                  let errorCode,
                                  let verificationResult,
                                  let cacheStatus,
                                  let responseTime):
                return (name: .getOfferingsResult,
                        properties: DiagnosticsEvent.Properties(
                            verificationResult: verificationResult?.name,
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            requestedProductIds: requestedProductIds,
                            notFoundProductIds: notFoundProductIds,
                            cacheStatus: cacheStatus
                        ))
            case .productsStarted(let requestedProductIds):
                return (name: .getProductsResult,
                        properties: DiagnosticsEvent.Properties(
                            requestedProductIds: requestedProductIds
                        ))
            case .productsResult(let requestedProductIds,
                                 let notFoundProductIds,
                                 let errorMessage,
                                 let errorCode,
                                 let responseTime):
                return (name: .getProductsResult,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            requestedProductIds: requestedProductIds,
                            notFoundProductIds: notFoundProductIds
                        ))
            case .getCustomerInfoStarted:
                return (name: .getCustomerInfoStarted, properties: .empty)
            case .getCustomerInfoResult(let cacheFetchPolicy,
                                        let verificationResult,
                                        let hadUnsyncedPurchasesBefore,
                                        let errorMessage,
                                        let errorCode,
                                        let responseTime):
                return (name: .getCustomerInfoResult,
                        properties: DiagnosticsEvent.Properties(
                            verificationResult: verificationResult?.name,
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            cacheFetchPolicy: cacheFetchPolicy,
                            hadUnsyncedPurchasesBefore: hadUnsyncedPurchasesBefore
                        ))
            case .syncPurchasesStarted:
                return (name: .syncPurchasesStarted, properties: .empty)
            case .syncPurchasesResult(let errorMessage,
                                      let errorCode,
                                      let responseTime):
                return (name: .syncPurchasesResult,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode
                        ))
            case .restorePurchasesStarted:
                return (name: .restorePurchasesStarted, properties: .empty)
            case .restorePurchasesResult(let errorMessage,
                                         let errorCode,
                                         let responseTime):
                return (name: .restorePurchasesResult,
                        properties: DiagnosticsEvent.Properties(
                            responseTime: responseTime,
                            errorMessage: errorMessage,
                            errorCode: errorCode
                        ))
            }
        }
    }
}
