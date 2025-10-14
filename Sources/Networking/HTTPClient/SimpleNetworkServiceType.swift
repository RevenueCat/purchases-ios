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
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
protocol SimpleNetworkServiceType {

    /// Fetch data from the network
    /// - Parameter url: The URL to fetch data from
    /// - Returns: Bytes upon success
    func bytes(from url: URL) async throws -> AsyncThrowingStream<UInt8, Error>
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
extension URLSession: SimpleNetworkServiceType {

    func bytes(from url: URL) async throws -> AsyncThrowingStream<UInt8, Error> {
        let (bytes, res) = try await bytes(for: .init(url: url), delegate: nil)
        if let httpURLResponse = res as? HTTPURLResponse, !(200..<300).contains(httpURLResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await byte in bytes {
                        continuation.yield(byte)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
