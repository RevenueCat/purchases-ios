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

/// An interface for storing and retrieving files from a local cache.
protocol LargeItemCacheType {
    /// Stores data at the given URL.
    func saveData(_ data: Data, to url: URL) throws

    /// Validates and moves a downloaded temporary file into the cache.
    ///
    /// This method takes ownership of the temporary file. It removes the file from
    /// `temporaryURL` whether validation and storage succeed or fail.
    ///
    /// - Parameters:
    ///   - temporaryURL: The location of the downloaded temporary file.
    ///   - destinationURL: The final cache location.
    ///   - checksum: An optional checksum used to validate the downloaded file before moving it.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    func saveDownloadedFile(fromTemporaryURL temporaryURL: URL, to destinationURL: URL, checksum: Checksum?) throws

    /// Checks whether non-empty content is cached at the URL.
    func cachedContentExists(at url: URL) -> Bool

    /// Loads data from the URL.
    func loadFile(at url: URL) throws -> Data

    /// Deletes data at the URL.
    func remove(_ url: URL) throws

    /// Creates a directory from a base path in the specified directory type
    /// The `inAppSpecificDirectory` should be set to false only for components
    /// that haven't migrated to the new app specific directory structure yet
    func createDirectoryIfNeeded(
        basePath: String,
        directoryType: DirectoryHelper.DirectoryType,
        inAppSpecificDirectory: Bool
    ) -> URL?

    /// Lists all file URLs in a directory.
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

    #if !os(tvOS)
    /// Creates a directory in the persistence (applicationSupport) directory from a base path.
    /// Defaults `inAppSpecificDirectory` to true.
    /// Note: tvOS only allows writes under the caches directory, so we don't provide this functionality there.
    func createPersistenceDirectoryIfNeeded(basePath: String, inAppSpecificDirectory: Bool = true) -> URL? {
        createDirectoryIfNeeded(
            basePath: basePath,
            directoryType: .applicationSupport(),
            inAppSpecificDirectory: inAppSpecificDirectory
        )
    }
    #endif
}

extension FileManager: LargeItemCacheType {

    /// Stores data at the given URL.
    func saveData(_ data: Data, to url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()
        try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try data.write(to: url, options: .atomic)
    }

    /// Validates and moves a downloaded temporary file into the cache.
    ///
    /// This method takes ownership of the temporary file. It removes the file from
    /// `temporaryURL` whether validation and storage succeed or fail.
    ///
    /// - Parameters:
    ///   - temporaryURL: The location of the downloaded temporary file.
    ///   - destinationURL: The final cache location.
    ///   - checksum: An optional checksum used to validate the downloaded file before moving it.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    func saveDownloadedFile(
        fromTemporaryURL temporaryURL: URL,
        to destinationURL: URL,
        checksum: Checksum?
    ) throws {
        // URLSession creates downloaded files in a temporary location. Ensure that file is
        // not leaked if checksum validation, directory creation, or the final move fails.
        defer { try? removeItem(at: temporaryURL) }

        if let checksum {
            let fileHandle = try FileHandle(forReadingFrom: temporaryURL)
            defer { try? fileHandle.close() }

            // Hash in bounded chunks so checksum validation does not load large assets into memory.
            // 256 KiB keeps memory usage low while avoiding excessive file-read operations.
            let checksumReadChunkSize = 256 * 1024
            var hasher = checksum.algorithm.getHasher()
            while let data = try fileHandle.read(upToCount: checksumReadChunkSize), !data.isEmpty {
                hasher.update(data: data)
            }

            // Do not move corrupted or incomplete downloads into the cache.
            let value = hasher.toString()
            try Checksum(algorithm: checksum.algorithm, value: value).compare(to: checksum)
        }

        // Validation is complete, so move the temporary file into its final cache location.
        let directoryURL = destinationURL.deletingLastPathComponent()
        try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try moveItem(at: temporaryURL, to: destinationURL)
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
