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

    func fetchCompiledWorkflowData(cdnUrl: String, completion: @escaping (Result<Data, Error>) -> Void)

}

/// Direct URL fetcher — downloads from the CDN URL via URLSession.
final class DirectWorkflowCdnFetcher: WorkflowCdnFetcher {

    func fetchCompiledWorkflowData(cdnUrl: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: cdnUrl) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse,
                      !(200..<300).contains(httpResponse.statusCode) {
                completion(.failure(URLError(.badServerResponse)))
            } else if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(URLError(.unknown)))
            }
        }.resume()
    }

}
