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

    /// Downloads a file from the network to a temporary location.
    /// - Parameter url: The URL to fetch data from
    /// - Returns: A temporary local file URL that the caller is responsible for consuming or removing.
    /// - Throws: `URLError.badServerResponse` when an HTTP response is outside the 2xx range.
    func downloadFile(from url: URL) async throws -> URL
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
extension URLSession: SimpleNetworkServiceType {

    /// Downloads a file to a temporary location without loading the complete response into memory.
    func downloadFile(from url: URL) async throws -> URL {
        let (temporaryURL, response) = try await self.download(from: url)
        return try validatedDownloadedFileURL(temporaryURL, response: response)
    }
}

/// Validates the response associated with a downloaded temporary file.
///
/// Non-HTTP responses pass through unchanged. For an unsuccessful HTTP response, this function
/// removes the temporary file before throwing `URLError.badServerResponse`.
///
/// - Parameters:
///   - temporaryURL: The location of the downloaded temporary file.
///   - response: The response associated with the download.
///   - fileManager: The file manager used to remove rejected downloads.
/// - Returns: `temporaryURL` when the response is valid.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
func validatedDownloadedFileURL(
    _ temporaryURL: URL,
    response: URLResponse,
    fileManager: FileManager = .default
) throws -> URL {
    if let httpURLResponse = response as? HTTPURLResponse,
       !(200..<300).contains(httpURLResponse.statusCode) {
        try? fileManager.removeItem(at: temporaryURL)
        throw URLError(.badServerResponse)
    }

    return temporaryURL
}
