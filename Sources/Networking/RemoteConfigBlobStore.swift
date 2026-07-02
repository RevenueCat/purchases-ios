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
    @discardableResult
    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool
    func cachedRefs() -> Set<String>
    func retainOnly(_ refs: Set<String>)
    func clear()
}

/// Content-addressed disk cache for remote config blobs, keyed by 32-character URL-safe base64 refs.
final class RemoteConfigBlobStore: RemoteConfigBlobStoreType {

    private let fileManager: FileManager
    private let directoryURL: URL?
    private let lock = Lock(.nonRecursive)

    /// Refs known to be on disk. Loaded once from a disk scan, then kept in sync by writes, pruning, and clear.
    /// If disk and index ever diverge, `read(ref:)` evicts stale refs on a miss so later fetches can recover.
    private var knownRefs: Set<String>?

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = RemoteConfigBlobStore.defaultDirectoryURL
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
    }

    func contains(ref: String) -> Bool {
        return self.lock.perform {
            return self.containsWithoutLock(ref: ref)
        }
    }

    func read(ref: String) -> Data? {
        return self.lock.perform {
            return self.readWithoutLock(ref: ref)
        }
    }

    @discardableResult
    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        return self.lock.perform {
            return self.writeWithoutLock(ref: ref, bytes: bytes)
        }
    }

    func cachedRefs() -> Set<String> {
        return self.lock.perform {
            return self.cachedRefsWithoutLock()
        }
    }

    func retainOnly(_ refs: Set<String>) {
        self.lock.perform {
            self.retainOnlyWithoutLock(refs)
        }
    }

    func clear() {
        self.lock.perform {
            self.clearWithoutLock()
        }
    }

}

private extension RemoteConfigBlobStore {

    func containsWithoutLock(ref: String) -> Bool {
        return self.loadedRefsWithoutLock().contains(ref)
    }

    func readWithoutLock(ref: String) -> Data? {
        guard let fileURL = self.fileURL(for: ref),
              self.isRegularFile(fileURL) else {
            self.knownRefs?.remove(ref)
            return nil
        }

        do {
            return try Data(contentsOf: fileURL)
        } catch {
            Logger.error(Strings.remoteConfig.failedToReadBlob(ref, error))
            return nil
        }
    }

    func writeWithoutLock(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        guard let directoryURL = self.directoryURL else {
            Logger.error(Strings.remoteConfig.cacheURLNotAvailable)
            return false
        }

        guard let fileURL = self.fileURL(for: ref) else {
            Logger.error(Strings.remoteConfig.malformedBlobRef(ref))
            return false
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
            var refs = self.loadedRefsWithoutLock()
            refs.insert(ref)
            self.knownRefs = refs
            return true
        } catch {
            Logger.error(Strings.remoteConfig.failedToWriteBlob(ref, error))
            return false
        }
    }

    func cachedRefsWithoutLock() -> Set<String> {
        return self.loadedRefsWithoutLock()
    }

    func retainOnlyWithoutLock(_ refs: Set<String>) {
        let validRefs = refs.filter(RemoteConfigBlobRefHelpers.isValid)
        refs.subtracting(validRefs).forEach { Logger.error(Strings.remoteConfig.malformedBlobRef($0)) }

        guard let directoryURL = self.directoryURL,
              let contents = try? self.fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
              ) else {
            self.knownRefs = []
            return
        }

        for fileURL in contents where self.isRegularFile(fileURL) && !validRefs.contains(fileURL.lastPathComponent) {
            do {
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                Logger.error(Strings.remoteConfig.failedToDeleteBlob(fileURL.lastPathComponent, error))
            }
        }

        self.knownRefs = self.loadedRefsWithoutLock().intersection(validRefs)
    }

    func clearWithoutLock() {
        guard let directoryURL = self.directoryURL,
              self.fileManager.fileExists(atPath: directoryURL.path) else {
            self.knownRefs = []
            return
        }

        do {
            try self.fileManager.removeItem(at: directoryURL)
        } catch {
            Logger.error(Strings.remoteConfig.failedToClearBlobStore(error))
        }

        self.knownRefs = []
    }

    static let blobsDirectoryName = "blobs"
    static var defaultDirectoryURL: URL? {
        return DirectoryHelper.baseUrl(for: RemoteConfigDiskCache.directoryType)?
            .appendingPathComponent(RemoteConfigDiskCache.basePath, isDirectory: true)
            .appendingPathComponent(Self.blobsDirectoryName, isDirectory: true)
    }

    func fileURL(for ref: String) -> URL? {
        guard RemoteConfigBlobRefHelpers.isValid(ref) else {
            return nil
        }

        return self.directoryURL?.appendingPathComponent(ref, isDirectory: false)
    }

    func isRegularFile(_ fileURL: URL) -> Bool {
        return (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }

    func loadedRefsWithoutLock() -> Set<String> {
        if let knownRefs {
            return knownRefs
        }

        guard let directoryURL = self.directoryURL,
              let contents = try? self.fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: []
              ) else {
            self.knownRefs = []
            return []
        }

        let scannedRefs = contents.reduce(into: Set<String>()) { refs, fileURL in
            guard self.isRegularFile(fileURL),
                  RemoteConfigBlobRefHelpers.isValid(fileURL.lastPathComponent) else {
                return
            }

            refs.insert(fileURL.lastPathComponent)
        }
        self.knownRefs = scannedRefs
        return scannedRefs
    }

}
