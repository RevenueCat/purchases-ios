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
    func track(_ event: DiagnosticsEvent)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackCustomerInfoVerificationResultIfNeeded(_ customerInfo: CustomerInfo)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    // swiftlint:disable:next function_parameter_count
    func trackProductsRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              responseTime: TimeInterval)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult)

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackPurchaseRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?)

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: DiagnosticsTrackerType, Sendable {

    private let diagnosticsFileHandler: DiagnosticsFileHandlerType
    private let diagnosticsDispatcher: OperationDispatcher
    private let dateProvider: DateProvider

    init(diagnosticsFileHandler: DiagnosticsFileHandlerType,
         diagnosticsDispatcher: OperationDispatcher = .default,
         dateProvider: DateProvider = DateProvider()) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
        self.diagnosticsDispatcher = diagnosticsDispatcher
        self.dateProvider = dateProvider
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
            eventType: .customerInfoVerificationResult,
            properties: [.verificationResultKey: AnyEncodable(verificationResult.name)],
            timestamp: self.dateProvider.now()
        )
        self.track(event)
    }

    // swiftlint:disable:next function_parameter_count
    func trackProductsRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?,
                              responseTime: TimeInterval) {
        self.track(
            DiagnosticsEvent(eventType: .appleProductsRequest,
                             properties: [
                                .successfulKey: AnyEncodable(wasSuccessful),
                                .storeKitVersion: AnyEncodable("store_kit_\(storeKitVersion.debugDescription)"),
                                .errorMessageKey: AnyEncodable(errorMessage),
                                .errorCodeKey: AnyEncodable(errorCode),
                                .skErrorDescriptionKey: AnyEncodable(storeKitErrorDescription),
                                .responseTimeMillisKey: AnyEncodable(responseTime * 1000)
                             ],
                             timestamp: self.dateProvider.now())
        )
    }

    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult) {
        self.track(
            DiagnosticsEvent(
                eventType: DiagnosticsEvent.EventType.httpRequestPerformed,
                properties: [
                    .endpointNameKey: AnyEncodable(endpointName),
                    .responseTimeMillisKey: AnyEncodable(responseTime * 1000),
                    .successfulKey: AnyEncodable(wasSuccessful),
                    .responseCodeKey: AnyEncodable(responseCode),
                    .backendErrorCodeKey: AnyEncodable(backendErrorCode),
                    .eTagHitKey: AnyEncodable(resultOrigin == .cache),
                    .verificationResultKey: AnyEncodable(verificationResult.name)
                ],
                timestamp: self.dateProvider.now()
            )
        )
    }

    func trackPurchaseRequest(wasSuccessful: Bool,
                              storeKitVersion: StoreKitVersion,
                              errorMessage: String?,
                              errorCode: Int?,
                              storeKitErrorDescription: String?) {
        self.track(
            DiagnosticsEvent(eventType: .applePurchaseAttempt,
                             properties: [
                                .successfulKey: AnyEncodable(wasSuccessful),
                                .storeKitVersion: AnyEncodable("store_kit_\(storeKitVersion.debugDescription)"),
                                .errorMessageKey: AnyEncodable(errorMessage),
                                .errorCodeKey: AnyEncodable(errorCode),
                                .skErrorDescriptionKey: AnyEncodable(storeKitErrorDescription)
                             ],
                             timestamp: self.dateProvider.now())
        )
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension DiagnosticsTracker {

    func clearDiagnosticsFileIfTooBig() async {
        if await self.diagnosticsFileHandler.isDiagnosticsFileTooBig() {
            await self.diagnosticsFileHandler.emptyDiagnosticsFile()
            let maxEventsStoredEvent = DiagnosticsEvent(eventType: .maxEventsStoredLimitReached,
                                                        properties: [:],
                                                        timestamp: self.dateProvider.now())
            await self.diagnosticsFileHandler.appendEvent(diagnosticsEvent: maxEventsStoredEvent)
        }
    }

}
