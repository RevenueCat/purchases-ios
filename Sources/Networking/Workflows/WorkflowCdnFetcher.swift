//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowCdnFetcher.swift
//
//  Created by RevenueCat.

import Foundation

/// Fetches compiled workflow JSON from a CDN URL.
protocol WorkflowCdnFetcher: Sendable {

    func fetchCompiledWorkflowData(cdnUrl: String) async throws -> Data

}

/// Direct URL fetcher — downloads from the CDN URL via URLSession.
final class DirectWorkflowCdnFetcher: WorkflowCdnFetcher {

    func fetchCompiledWorkflowData(cdnUrl: String) async throws -> Data {
        guard let url = URL(string: cdnUrl) else {
            throw URLError(.badURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let httpResponse = response as? HTTPURLResponse,
                          !(200..<300).contains(httpResponse.statusCode) {
                    continuation.resume(throwing: URLError(.badServerResponse))
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: URLError(.unknown))
                }
            }.resume()
        }
    }

}
