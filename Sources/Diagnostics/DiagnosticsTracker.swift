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

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
protocol DiagnosticsTrackerType {

    func track(_ event: DiagnosticsEvent) async
    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(
        endpoint: HTTPRequestPath,
        responseTime: TimeInterval,
        wasSuccessful: Bool,
        responseCode: Int,
        resultOrigin: HTTPResponseOrigin?,
        verificationResult: VerificationResult
    )

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: DiagnosticsTrackerType {

    private let diagnosticsFileHandler: DiagnosticsFileHandler

    init(diagnosticsFileHandler: DiagnosticsFileHandler) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
    }

    func track(_ event: DiagnosticsEvent) async {
        await diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
    }

    // swiftlint:disable:next function_parameter_count
    func trackHttpRequestPerformed(
        endpoint: HTTPRequestPath,
        responseTime: TimeInterval,
        wasSuccessful: Bool,
        responseCode: Int,
        resultOrigin: HTTPResponseOrigin?,
        verificationResult: VerificationResult
    ) {
        let eTagHit = resultOrigin == .cache
        Task {
            await track(
                DiagnosticsEvent(
                    eventType: DiagnosticsEvent.EventType.httpRequestPerformed,
                    properties: [
                        "endpoint_name": AnyEncodable(endpoint.name),
                        "response_time_millis": AnyEncodable(responseTime * 1000),
                        "successful": AnyEncodable(wasSuccessful),
                        "response_code": AnyEncodable(responseCode),
                        "etag_hit": AnyEncodable(eTagHit),
                        "verification_result": AnyEncodable(verificationResult.name)
                    ]
                )
            )
        }
    }
}
