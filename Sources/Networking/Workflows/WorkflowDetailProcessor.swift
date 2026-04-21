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
///   - expectedHash: The SHA-256 hash the server advertised for this content, if any.
///   - completion: Called with the raw `Data` on success, or an `Error` on failure.
typealias WorkflowCdnFetch = @Sendable (String, String?, @escaping (Result<Data, Error>) -> Void) -> Void

/// Typed errors thrown by `WorkflowDetailProcessor` so callers can distinguish failure modes.
enum WorkflowDetailProcessingError: Error {

    case cdnFetchFailed(Error)
    case invalidEnvelopeJson
    case unknownAction(String)
    case missingCdnUrl
    case cdnHashMismatch

}

struct WorkflowDetailProcessingResult {

    let workflow: PublishedWorkflow
    let enrolledVariants: [String: String]?

}

final class WorkflowDetailProcessor: Sendable {

    private let cdnFetch: WorkflowCdnFetch

    init(cdnFetch: @escaping WorkflowCdnFetch) {
        self.cdnFetch = cdnFetch
    }

    func process(_ data: Data, completion: @escaping (Result<WorkflowDetailProcessingResult, Error>) -> Void) {
        guard let json = try? data.asJSONDictionary() else {
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
            self.processInline(rawData: data, enrolledVariants: enrolledVariants, completion: completion)

        case .useCdn:
            self.processCdn(json: json, enrolledVariants: enrolledVariants, completion: completion)
        }
    }

    private struct InlineEnvelope: Decodable {
        let data: PublishedWorkflow
    }

    private func processInline(
        rawData: Data,
        enrolledVariants: [String: String]?,
        completion: @escaping (Result<WorkflowDetailProcessingResult, Error>) -> Void
    ) {
        do {
            let envelope = try JSONDecoder.default.decode(InlineEnvelope.self, jsonData: rawData)
            completion(.success(.init(workflow: envelope.data, enrolledVariants: enrolledVariants)))
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

        self.cdnFetch(cdnUrl, expectedHash) { result in
            switch result {
            case .success(let cdnData):
                if let error = self.verifyCdnHashIfNeeded(cdnData, expectedHash: expectedHash) {
                    completion(.failure(error))
                    return
                }
                do {
                    let workflow = try PublishedWorkflow.create(with: cdnData)
                    completion(.success(.init(workflow: workflow, enrolledVariants: enrolledVariants)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                if case WorkflowDetailProcessingError.cdnHashMismatch = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(WorkflowDetailProcessingError.cdnFetchFailed(error)))
                }
            }
        }
    }

    private func verifyCdnHashIfNeeded(_ data: Data, expectedHash: String?) -> Error? {
        guard let expectedHash else { return nil }

        guard Self.verifyCdnHash(data, expectedHash: expectedHash) else {
            Logger.warn(Strings.network.workflow_cdn_hash_mismatch)
            return WorkflowDetailProcessingError.cdnHashMismatch
        }

        return nil
    }

    static func verifyCdnHash(_ data: Data, expectedHash: String) -> Bool {
        return data.sha256String == expectedHash
    }

}
