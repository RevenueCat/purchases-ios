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

    private let cache: LargeItemCacheType
    private let directoryURL: URL?
    private let lock = Lock(.nonRecursive)

    /// Refs known to be on disk. Loaded once from a disk scan, then kept in sync by writes, pruning, and clear.
    /// If disk and index ever diverge, `read(ref:)` evicts stale refs on a miss so later fetches can recover.
    private var knownRefs: Set<String>?

    init(
        cache: LargeItemCacheType = FileManager.default,
        directoryURL: URL? = RemoteConfigBlobStore.defaultDirectoryURL
    ) {
        self.cache = cache
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
            return self.loadedRefsWithoutLock()
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
        guard self.loadedRefsWithoutLock().contains(ref),
              let fileURL = self.fileURL(for: ref),
              self.cache.cachedFileExists(at: fileURL) else {
            self.knownRefs?.remove(ref)
            return false
        }

        return true
    }

    func readWithoutLock(ref: String) -> Data? {
        guard let fileURL = self.fileURL(for: ref),
              self.cache.cachedFileExists(at: fileURL) else {
            self.knownRefs?.remove(ref)
            return nil
        }

        do {
            return try self.cache.loadFile(at: fileURL)
        } catch {
            Logger.error(Strings.remoteConfig.failedToReadBlob(ref, error))
            return nil
        }
    }

    func writeWithoutLock(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        guard self.directoryURL != nil else {
            Logger.error(Strings.remoteConfig.cacheURLNotAvailable)
            return false
        }

        guard let fileURL = self.fileURL(for: ref) else {
            Logger.error(Strings.remoteConfig.malformedBlobRef(ref))
            return false
        }

        do {
            var data = Data()
            data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
            try self.cache.saveData(data, to: fileURL)
            guard var refs = self.knownRefs else {
                return true
            }

            refs.insert(ref)
            self.knownRefs = refs
            return true
        } catch {
            Logger.error(Strings.remoteConfig.failedToWriteBlob(ref, error))
            return false
        }
    }

    func retainOnlyWithoutLock(_ refs: Set<String>) {
        let validRefs = refs.filter(RemoteConfigBlobRefHelpers.isValid)
        refs.subtracting(validRefs).forEach { Logger.error(Strings.remoteConfig.malformedBlobRef($0)) }

        guard let directoryURL = self.directoryURL else {
            self.knownRefs = []
            return
        }

        guard let contents = try? self.cache.contentsOfDirectory(at: directoryURL) else {
            self.knownRefs = nil
            return
        }

        for fileURL in contents where self.cache.cachedFileExists(at: fileURL)
            && !validRefs.contains(fileURL.lastPathComponent) {
            do {
                try self.cache.remove(fileURL)
            } catch {
                Logger.error(Strings.remoteConfig.failedToDeleteBlob(fileURL.lastPathComponent, error))
            }
        }

        self.knownRefs = self.scannedRefsWithoutLock()?.intersection(validRefs)
    }

    func clearWithoutLock() {
        guard let directoryURL = self.directoryURL else {
            self.knownRefs = []
            return
        }

        do {
            try self.cache.remove(directoryURL)
            self.knownRefs = []
        } catch {
            guard !self.isMissingFileError(error) else {
                self.knownRefs = []
                return
            }

            Logger.error(Strings.remoteConfig.failedToClearBlobStore(error))
            self.knownRefs = nil
        }
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

    func isMissingFileError(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == NSCocoaErrorDomain && error.code == CocoaError.fileNoSuchFile.rawValue
    }

    func loadedRefsWithoutLock() -> Set<String> {
        if let knownRefs {
            return knownRefs
        }

        guard self.directoryURL != nil else {
            self.knownRefs = []
            return []
        }

        guard let scannedRefs = self.scannedRefsWithoutLock() else {
            return []
        }

        self.knownRefs = scannedRefs
        return scannedRefs
    }

    func scannedRefsWithoutLock() -> Set<String>? {
        guard let directoryURL = self.directoryURL,
              let contents = try? self.cache.contentsOfDirectory(at: directoryURL) else {
            return nil
        }

        let scannedRefs = contents.reduce(into: Set<String>()) { refs, fileURL in
            guard self.cache.cachedFileExists(at: fileURL),
                  RemoteConfigBlobRefHelpers.isValid(fileURL.lastPathComponent) else {
                return
            }

            refs.insert(fileURL.lastPathComponent)
        }
        return scannedRefs
    }

}
