//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LargeItemCacheType.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation

/// An inteface representing a simple cache
protocol LargeItemCacheType {
    /// Store data to a url
    func saveData(_ data: Data, to url: URL) throws

    /// Store data to a url
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    func saveData(_ bytes: AsyncThrowingStream<UInt8, Error>, to url: URL, checksum: Checksum?) async throws

    /// Check if there is content cached at the url
    func cachedContentExists(at url: URL) -> Bool

    /// Load data from url
    func loadFile(at url: URL) throws -> Data

    /// delete data at url
    func remove(_ url: URL) throws

    /// Creates a directory in the cache from a base path
    func createCacheDirectoryIfNeeded(basePath: String) -> URL?

    /// Creates a directory in the documents directory from a base path
    func createDocumentDirectoryIfNeeded(basePath: String) -> URL?
}

extension FileManager: LargeItemCacheType {
    /// A URL for a cache directory if one is present
    private var cacheDirectory: URL? {
        return urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    ///// A URL for a document directory if one is present
    private var documentDirectory: URL? {
        return urls(for: .documentDirectory, in: .userDomainMask).first
    }

    /// Store data to a url
    func saveData(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }

    /// Store data to a url and validate that the file is correct before saving
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    func saveData(
        _ bytes: AsyncThrowingStream<UInt8, Error>,
        to url: URL,
        checksum: Checksum?
    ) async throws {

        // Set up file handling

        let tempFileURL = temporaryDirectory.appendingPathComponent((checksum?.value ?? "") + url.lastPathComponent)

        guard createFile(atPath: tempFileURL.path, contents: nil, attributes: nil) else {
            let message = Strings.fileRepository.failedToCreateTemporaryFile(tempFileURL).description
            Logger.error(message)
            throw CocoaError(.fileWriteUnknown)
        }

        let fileHandle = try FileHandle(forWritingTo: tempFileURL)
        defer { try? fileHandle.close() }
        defer { try? removeItem(at: tempFileURL) }

        // Write data in chunks to the temporary file

        let bufferSize: Int = 262_144 // 256KB
        var buffer = Data()
        buffer.reserveCapacity(bufferSize)
        var hasher = checksum?.algorithm.getHasher()

        for try await byte in bytes {
            buffer.append(byte)

            if buffer.count >= bufferSize {
                hasher?.update(data: buffer)
                try fileHandle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
            }
        }

        // Write any remaining bytes missed during the while loop
        if !buffer.isEmpty {
            hasher?.update(data: buffer)
            try fileHandle.write(contentsOf: buffer)
        }

        // Validate the stored data matches what the server has
        if let checksum = checksum, let hasher = hasher {
            // If this fails… should we retry?

            let digest = hasher.finalize()
            let value = digest.compactMap { String(format: "%02x", $0) }.joined()
            try Checksum(algorithm: checksum.algorithm, value: value)
                .compare(to: checksum)
        }

        // If all succeeds, move the temporary file to the more permanant storage location
        // effectively a "save" operation
        try moveItem(at: tempFileURL, to: url)
    }

    /// Check if there is content cached at the given path
    func cachedContentExists(at url: URL) -> Bool {
        do {
            if let size = try self.attributesOfItem(atPath: url.path)[.size] as? UInt64 {
                return size > 0
            }
            return false
        } catch {
            return false
        }
    }

    /// Creates a directory in the cache from a base path
    func createCacheDirectoryIfNeeded(basePath: String) -> URL? {
        guard let cacheDirectory else {
            return nil
        }

        let path = cacheDirectory.appendingPathComponent(basePath)
        do {
            try createDirectory(
                at: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            let message = Strings.fileRepository.failedToCreateCacheDirectory(path).description
            Logger.error(message)
        }

        return path
    }

    /// Creates a directory in the documents directory from a base path
    func createDocumentDirectoryIfNeeded(basePath: String) -> URL? {
        guard let documentDirectory else {
            return nil
        }

        let path = documentDirectory.appendingPathComponent(basePath)
        do {
            try createDirectory(
                at: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            let message = Strings.fileRepository.failedToCreateDocumentDirectory(path).description
            Logger.error(message)
        }

        return path
    }

    /// Load data from url
    func loadFile(at url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    func remove(_ url: URL) throws {
        try self.removeItem(at: url)
    }
}
