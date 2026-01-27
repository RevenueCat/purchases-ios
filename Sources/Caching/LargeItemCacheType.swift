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

    /// Creates a directory from a base path in the specified directory type
    /// The `inAppSpecificDirectory` should be set to false only for components
    /// that haven't migrated to the new app specific directory structure yet
    func createDirectoryIfNeeded(
        basePath: String,
        directoryType: DirectoryHelper.DirectoryType,
        inAppSpecificDirectory: Bool
    ) -> URL?

    /// List all file URLs in a directory
    func contentsOfDirectory(at url: URL) throws -> [URL]
}

extension LargeItemCacheType {
    /// Creates a directory in the cache from a base path. Defaults `inAppSpecificDirectory` to true.
    func createCacheDirectoryIfNeeded(basePath: String, inAppSpecificDirectory: Bool = true) -> URL? {
        createDirectoryIfNeeded(
            basePath: basePath,
            directoryType: .cache,
            inAppSpecificDirectory: inAppSpecificDirectory
        )
    }

    /// Creates a directory in the persistence (applicationSupport) directory from a base path.
    /// Defaults `inAppSpecificDirectory` to true.
    func createPersistenceDirectoryIfNeeded(basePath: String, inAppSpecificDirectory: Bool = true) -> URL? {
        createDirectoryIfNeeded(
            basePath: basePath,
            directoryType: .applicationSupport(),
            inAppSpecificDirectory: inAppSpecificDirectory
        )
    }
}

extension FileManager: LargeItemCacheType {

    /// Store data to a url
    func saveData(_ data: Data, to url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()
        try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
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
            let message = Strings.fileRepository.failedToCreateTemporaryFile(tempFileURL)
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
        let directoryURL = url.deletingLastPathComponent()
        try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
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

    /// Creates a directory from a base path in the specified directory type
    /// The `inAppSpecificDirectory` should be set to false only for components
    /// that haven't migrated to the new app specific directory structure yet
    func createDirectoryIfNeeded(
        basePath: String,
        directoryType: DirectoryHelper.DirectoryType,
        inAppSpecificDirectory: Bool
    ) -> URL? {
        guard let baseDirectoryURL = DirectoryHelper.baseUrl(
            for: directoryType,
            inAppSpecificDirectory: inAppSpecificDirectory
        ) else { return nil }

        let directoryURL = baseDirectoryURL.appendingPathComponent(basePath)
        do {
            try createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            let message = Strings.fileRepository.failedToCreateCacheDirectory(directoryURL)
            Logger.error(message)
        }

        return directoryURL
    }

    /// Load data from url
    func loadFile(at url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    func remove(_ url: URL) throws {
        try self.removeItem(at: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
    }
}
