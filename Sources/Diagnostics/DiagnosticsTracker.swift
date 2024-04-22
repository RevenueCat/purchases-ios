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
    func trackCustomerInfoVerificationResultIfNeeded(_ customerInfo: CustomerInfo,
                                                     timestamp: Date) async

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: DiagnosticsTrackerType {

    private let diagnosticsFileHandler: DiagnosticsFileHandlerType

    init(diagnosticsFileHandler: DiagnosticsFileHandlerType) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
    }

    func track(_ event: DiagnosticsEvent) async {
        await diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
    }

    func trackCustomerInfoVerificationResultIfNeeded(
        _ customerInfo: CustomerInfo,
        timestamp: Date = Date()
    ) async {
        let verificationResult = customerInfo.entitlements.verification
        if verificationResult == .notRequested {
            return
        }

        let event = DiagnosticsEvent(
            eventType: .customerInfoVerificationResult,
            properties: [.verificationResultKey: AnyEncodable(verificationResult.name)],
            timestamp: timestamp
        )
        await track(event)
    }

}
