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

/// A closure that fetches compiled workflow JSON from a CDN URL.
///
/// - Parameters:
///   - cdnUrl: The CDN URL string to fetch from.
///   - completion: Called with the raw `Data` on success, or an `Error` on failure.
typealias WorkflowCdnFetch = @Sendable (String, @escaping (Result<Data, Error>) -> Void) -> Void

/// Typed errors thrown by `WorkflowDetailProcessor` so callers can distinguish failure modes.
enum WorkflowDetailProcessingError: Error {

    case cdnFetchFailed(Error)
    case invalidEnvelopeJson
    case unknownAction(String)
    case missingInlineData
    case missingCdnUrl
    case missingCdnHash
    case cdnHashMismatch

}

struct WorkflowDetailProcessingResult {

    let workflowData: Data
    let enrolledVariants: [String: String]?

}

/// Normalizes a successful workflow-detail HTTP payload:
/// `inline` (unwraps `data`) or `use_cdn` (fetches JSON from CDN).
final class WorkflowDetailProcessor: Sendable {

    private let cdnFetch: WorkflowCdnFetch
    private let responseVerificationMode: Signing.ResponseVerificationMode

    init(cdnFetch: @escaping WorkflowCdnFetch,
         responseVerificationMode: Signing.ResponseVerificationMode) {
        self.cdnFetch = cdnFetch
        self.responseVerificationMode = responseVerificationMode
    }

    func process(_ data: Data, completion: @escaping (Result<WorkflowDetailProcessingResult, Error>) -> Void) {
        guard let json = Self.parseEnvelope(data) else {
            completion(.failure(WorkflowDetailProcessingError.invalidEnvelopeJson))
            return
        }

        let enrolledVariants = json["enrolled_variants"] as? [String: String]

        guard let actionString = json["action"] as? String,
              let action = WorkflowResponseAction(rawValue: actionString) else {
            let actionValue = json["action"] as? String ?? "nil"
            completion(.failure(WorkflowDetailProcessingError.unknownAction(actionValue)))
            return
        }

        switch action {
        case .inline:
            self.processInline(json: json, enrolledVariants: enrolledVariants, completion: completion)

        case .useCdn:
            self.processCdn(json: json, enrolledVariants: enrolledVariants, completion: completion)
        }
    }

    private static func parseEnvelope(_ data: Data) -> [String: Any]? {
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private func processInline(
        json: [String: Any],
        enrolledVariants: [String: String]?,
        completion: @escaping (Result<WorkflowDetailProcessingResult, Error>) -> Void
    ) {
        guard let inlineData = json["data"] else {
            completion(.failure(WorkflowDetailProcessingError.missingInlineData))
            return
        }
        do {
            let workflowData = try JSONSerialization.data(withJSONObject: inlineData)
            completion(.success(.init(workflowData: workflowData, enrolledVariants: enrolledVariants)))
        } catch {
            completion(.failure(error))
        }
    }

    private func processCdn(
        json: [String: Any],
        enrolledVariants: [String: String]?,
        completion: @escaping (Result<WorkflowDetailProcessingResult, Error>) -> Void
    ) {
        guard let cdnUrl = json["url"] as? String else {
            completion(.failure(WorkflowDetailProcessingError.missingCdnUrl))
            return
        }
        let expectedHash = json["hash"] as? String

        self.cdnFetch(cdnUrl) { result in
            switch result {
            case .success(let workflowData):
                if let error = self.verifyCdnHashIfNeeded(workflowData, expectedHash: expectedHash) {
                    completion(.failure(error))
                    return
                }
                completion(.success(.init(workflowData: workflowData, enrolledVariants: enrolledVariants)))
            case .failure(let error):
                completion(.failure(WorkflowDetailProcessingError.cdnFetchFailed(error)))
            }
        }
    }

    /// Returns an error if hash verification fails and enforcement requires it. Returns `nil` if verification
    /// passes or is not enabled.
    private func verifyCdnHashIfNeeded(_ data: Data, expectedHash: String?) -> Error? {
        guard self.responseVerificationMode.isEnabled else { return nil }

        guard let expectedHash else {
            Logger.warn(Strings.network.workflow_cdn_hash_missing)
            return self.responseVerificationMode.isEnforced ? WorkflowDetailProcessingError.missingCdnHash : nil
        }

        guard Self.verifyCdnHash(data, expectedHash: expectedHash) else {
            Logger.warn(Strings.network.workflow_cdn_hash_mismatch)
            return self.responseVerificationMode.isEnforced ? WorkflowDetailProcessingError.cdnHashMismatch : nil
        }

        return nil
    }

    static func verifyCdnHash(_ data: Data, expectedHash: String) -> Bool {
        return data.sha256String == expectedHash
    }

}
