//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowDetailProcessor.swift
//
//  Created by RevenueCat.

import Foundation

/// Typed errors thrown by `WorkflowDetailProcessor` so callers can distinguish
/// CDN network failures from envelope parsing failures.
enum WorkflowDetailProcessingError: Error {

    case cdnFetchFailed(Error)

}

struct WorkflowDetailProcessingResult {

    let workflowData: Data
    let enrolledVariants: [String: String]?

}

/// Normalizes a successful workflow-detail HTTP payload:
/// `inline` (unwraps `data`) or `use_cdn` (fetches JSON from CDN).
final class WorkflowDetailProcessor: Sendable {

    private let cdnFetcher: WorkflowCdnFetcher

    init(cdnFetcher: WorkflowCdnFetcher) {
        self.cdnFetcher = cdnFetcher
    }

    func process(_ data: Data) async throws -> WorkflowDetailProcessingResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let json else {
            throw Self.processingError("Failed to parse workflow detail envelope as JSON dictionary")
        }

        let enrolledVariants = (json["enrolled_variants"] as? [String: String])

        guard let actionString = json["action"] as? String,
              let action = WorkflowResponseAction(rawValue: actionString) else {
            let actionValue = json["action"] as? String ?? "nil"
            throw Self.processingError("Unknown workflow response action: \(actionValue)")
        }

        let workflowData: Data
        switch action {
        case .inline:
            guard let inlineData = json["data"] else {
                throw Self.processingError("Missing 'data' in inline workflow response")
            }
            workflowData = try JSONSerialization.data(withJSONObject: inlineData)

        case .useCdn:
            guard let cdnUrl = json["url"] as? String else {
                throw Self.processingError("Missing 'url' in use_cdn workflow response")
            }
            do {
                workflowData = try await self.cdnFetcher.fetchCompiledWorkflowData(cdnUrl: cdnUrl)
            } catch {
                throw WorkflowDetailProcessingError.cdnFetchFailed(error)
            }
        }

        return WorkflowDetailProcessingResult(
            workflowData: workflowData,
            enrolledVariants: enrolledVariants
        )
    }

    private static func processingError(_ message: String) -> Error {
        NSError(domain: "RevenueCat.WorkflowDetailProcessor",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }

}
