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

/// Direct URL fetcher — downloads from the CDN URL synchronously.
final class DirectWorkflowCdnFetcher: WorkflowCdnFetcher {

    func fetchCompiledWorkflowData(cdnUrl: String) throws -> Data {
        guard let url = URL(string: cdnUrl) else {
            throw URLError(.badURL)
        }
        return try Data(contentsOf: url)
    }

}
