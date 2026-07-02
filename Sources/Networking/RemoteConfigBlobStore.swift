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
        guard let fileURL = self.fileURL(for: ref) else {
            return false
        }

        return self.isRegularFile(fileURL)
    }

    func readWithoutLock(ref: String) -> Data? {
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
            return true
        } catch {
            Logger.error(Strings.remoteConfig.failedToWriteBlob(ref, error))
            return false
        }
    }

    func cachedRefsWithoutLock() -> Set<String> {
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
                  RemoteConfigBlobRefHelpers.isValid(fileURL.lastPathComponent) else {
                return
            }

            refs.insert(fileURL.lastPathComponent)
        }
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
            return
        }

        for fileURL in contents where self.isRegularFile(fileURL) && !validRefs.contains(fileURL.lastPathComponent) {
            do {
                try self.fileManager.removeItem(at: fileURL)
            } catch {
                Logger.error(Strings.remoteConfig.failedToDeleteBlob(fileURL.lastPathComponent, error))
            }
        }
    }

    func clearWithoutLock() {
        guard let directoryURL = self.directoryURL,
              self.fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        do {
            try self.fileManager.removeItem(at: directoryURL)
        } catch {
            Logger.error(Strings.remoteConfig.failedToClearBlobStore(error))
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

    func isRegularFile(_ fileURL: URL) -> Bool {
        return (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
    }
}
