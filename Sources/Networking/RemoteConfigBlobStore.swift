//
//  RemoteConfigBlobStore.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigBlobStoreType: AnyObject {

    func contains(ref: String) -> Bool

    func read(ref: String) -> Data?

    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    )

    func cachedRefs() -> Set<String>

    func retainOnly(_ refs: Set<String>)

}

/// Content-addressed disk cache for remote config blobs.
///
/// Blob refs are 32-character URL-safe base64 strings, so valid refs can be used as filenames directly.
/// Malformed refs are rejected before file access to keep all operations contained to the blobs directory.
final class RemoteConfigBlobStore: RemoteConfigBlobStoreType {

    private let fileManager: FileManager
    private let directoryURL: URL?

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = RemoteConfigBlobStore.defaultDirectoryURL
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
    }

    func contains(ref: String) -> Bool {
        guard let fileURL = self.fileURL(for: ref) else {
            return false
        }

        return self.isRegularFile(fileURL)
    }

    func read(ref: String) -> Data? {
        guard let fileURL = self.fileURL(for: ref),
              self.fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            return try Data(contentsOf: fileURL)
        } catch {
            Logger.error(Strings.remoteConfig.failedToReadBlob(ref, error))
            return nil
        }
    }

    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) {
        guard let directoryURL = self.directoryURL else {
            Logger.error(Strings.remoteConfig.cacheURLNotAvailable)
            return
        }

        guard let fileURL = self.fileURL(for: ref) else {
            Logger.error(Strings.remoteConfig.malformedBlobRef(ref))
            return
        }

        do {
            try self.fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            var data = Data()
            data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Logger.error(Strings.remoteConfig.failedToWriteBlob(ref, error))
        }
    }

    func cachedRefs() -> Set<String> {
        guard let directoryURL = self.directoryURL,
              let contents = try? self.fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
              ) else {
            return []
        }

        return contents.reduce(into: Set<String>()) { refs, fileURL in
            guard self.isRegularFile(fileURL),
                  Self.isValidRef(fileURL.lastPathComponent) else {
                return
            }

            refs.insert(fileURL.lastPathComponent)
        }
    }

    func retainOnly(_ refs: Set<String>) {
        guard let directoryURL = self.directoryURL,
              let contents = try? self.fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
              ) else {
            return
        }

        for fileURL in contents where self.isRegularFile(fileURL) && !refs.contains(fileURL.lastPathComponent) {
            do {
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                Logger.error(Strings.remoteConfig.failedToDeleteBlob(fileURL.lastPathComponent, error))
            }
        }
    }

}

private extension RemoteConfigBlobStore {

    static let blobsDirectoryName = "blobs"
    static let validRefPattern = #"^[A-Za-z0-9_-]{32}$"#

    static var defaultDirectoryURL: URL? {
        return DirectoryHelper.baseUrl(for: RemoteConfigDiskCache.directoryType)?
            .appendingPathComponent(RemoteConfigDiskCache.basePath, isDirectory: true)
            .appendingPathComponent(Self.blobsDirectoryName, isDirectory: true)
    }

    static func isValidRef(_ ref: String) -> Bool {
        return ref.range(of: Self.validRefPattern, options: .regularExpression) != nil
    }

    func fileURL(for ref: String) -> URL? {
        guard Self.isValidRef(ref) else {
            return nil
        }

        return self.directoryURL?.appendingPathComponent(ref, isDirectory: false)
    }

    func isRegularFile(_ fileURL: URL) -> Bool {
        return (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }

}
