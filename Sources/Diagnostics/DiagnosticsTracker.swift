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
    func track(_ event: DiagnosticsEvent) async

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func trackCustomerInfoVerificationResultIfNeeded(_ customerInfo: CustomerInfo) async

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult) async

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: DiagnosticsTrackerType {

    private let diagnosticsFileHandler: DiagnosticsFileHandlerType
    private let dateProvider: DateProvider

    init(diagnosticsFileHandler: DiagnosticsFileHandlerType,
         dateProvider: DateProvider = DateProvider()) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
        self.dateProvider = dateProvider
    }

    func track(_ event: DiagnosticsEvent) async {
        await self.clearDiagnosticsFileIfTooBig()
        await self.diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
    }

    func trackCustomerInfoVerificationResultIfNeeded(
        _ customerInfo: CustomerInfo
    ) async {
        let verificationResult = customerInfo.entitlements.verification
        if verificationResult == .notRequested {
            return
        }

        let event = DiagnosticsEvent(
            eventType: .customerInfoVerificationResult,
            properties: [.verificationResultKey: AnyEncodable(verificationResult.name)],
            timestamp: self.dateProvider.now()
        )
        await track(event)
    }

    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(endpointName: String,
                                   responseTime: TimeInterval,
                                   wasSuccessful: Bool,
                                   responseCode: Int,
                                   backendErrorCode: Int?,
                                   resultOrigin: HTTPResponseOrigin?,
                                   verificationResult: VerificationResult) async {
        await track(
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

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension DiagnosticsTracker {

    func clearDiagnosticsFileIfTooBig() async {
        if await self.diagnosticsFileHandler.isDiagnosticsFileTooBig() {
            await self.diagnosticsFileHandler.emptyDiagnosticsFile()
            await self.trackMaxEventsStoredLimitReached()
        }
    }

    func trackMaxEventsStoredLimitReached() async {
        await self.track(.init(eventType: .maxEventsStoredLimitReached,
                               properties: [:],
                               timestamp: self.dateProvider.now()))
    }

}
