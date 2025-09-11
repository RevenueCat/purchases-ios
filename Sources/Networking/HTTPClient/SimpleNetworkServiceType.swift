//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimpleNetworkServiceType.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/25.

import Foundation

/// A protocol representing a simple network service
protocol SimpleNetworkServiceType {
    /// Fetch data from the network
    /// - Parameter url: The URL to fetch data from
    /// - Returns: Data upon success
    func data(from url: URL) async throws -> Data
}

extension URLSession: SimpleNetworkServiceType {
    /// Fetch data from the network
    /// - Parameter url: The URL to fetch data from
    /// - Returns: Data upon success
    func data(from url: URL) async throws -> Data {
        let (data, response) = try await data(from: url)
        if let httpURLResponse = response as? HTTPURLResponse, !(200..<300).contains(httpURLResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
