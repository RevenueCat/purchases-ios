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

    func fetchCompiledWorkflowData(cdnUrl: String) throws -> Data

}

/// Direct URL fetcher — downloads from the CDN URL using URLSession.
final class DirectWorkflowCdnFetcher: WorkflowCdnFetcher {

    func fetchCompiledWorkflowData(cdnUrl: String) throws -> Data {
        guard let url = URL(string: cdnUrl) else {
            throw URLError(.badURL)
        }

        var fetchResult: Result<Data, Error> = .failure(URLError(.unknown))
        let semaphore = DispatchSemaphore(value: 0)

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }

            if let error = error {
                fetchResult = .failure(error)
            } else if let httpResponse = response as? HTTPURLResponse,
                      !(200..<300).contains(httpResponse.statusCode) {
                fetchResult = .failure(URLError(.badServerResponse))
            } else if let data = data {
                fetchResult = .success(data)
            } else {
                fetchResult = .failure(URLError(.unknown))
            }
        }.resume()

        semaphore.wait()
        return try fetchResult.get()
    }

}
