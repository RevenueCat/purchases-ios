//
//  FileImageLoader.swift
//
//
//  Created by RevenueCat on 11/4/25.
//

import Foundation
@_spi(Internal) import RevenueCat

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import SwiftUI

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class FileImageLoader: ObservableObject {

    let fileRepository: FileRepository
    @MainActor private(set) var url: URL?
    private let cachedAlternativeURL: URL?

    @MainActor
    init(fileRepository: FileRepository, url: URL?, cachedAlternativeURL: URL? = nil) {
        self.cachedAlternativeURL = cachedAlternativeURL
        self.fileRepository = fileRepository
        self.url = url
        self.loadFromCache(url: url)
    }

    typealias Value = (image: Image, size: CGSize)

    @MainActor
    private func loadFromCache(url: URL?) {
        guard self.cachedAlternativeURL == nil, let url = url else {
            return
        }

        let result = self.cachedImage(for: url)
        self.wasLoadedFromCache = result != nil
        self.result = result
    }

    private func cachedImage(for url: URL) -> Value? {
        if let result = DecodedImageCache.shared.cachedImageAndSize(for: url) {
            return result
        }
        let result = self.fileRepository.getCachedFileURL(for: url, withChecksum: nil)?.asImageAndSize
        if let result {
            DecodedImageCache.shared.cacheImageAndSize(result, for: url)
        }
        return result
    }

    @Published @MainActor
    private(set) var result: Value?

    @MainActor
    private(set) var wasLoadedFromCache: Bool = false

    @MainActor
    func updateURL(_ url: URL?) {
        guard url != self.url else {
            return
        }

        // Reset cached state when the URL changes so callers don't need to recreate the loader.
        self.url = url
        self.wasLoadedFromCache = false
        self.result = nil
        self.loadFromCache(url: url)
    }

    func load() async {
        let pendingURL = await MainActor.run { self.result == nil ? self.url : nil }
        guard let url = pendingURL else {
            return
        }

        if let alternative = self.cachedAlternativeURL,
           let cached = self.cachedImage(for: alternative) ?? DecodedImageCache.shared.cachedImageAndSize(for: url) {
            await MainActor.run {
                guard !Task.isCancelled, self.url == url else { return }
                self.result = cached
                self.wasLoadedFromCache = true
            }
            return
        }

        do {
            let imageInfo = try await self.fileRepository.generateOrGetCachedFileURL(
                for: url, withChecksum: nil
            ).asImageAndSize

            guard !Task.isCancelled else {
                return
            }

            if let imageInfo {
                DecodedImageCache.shared.cacheImageAndSize(imageInfo, for: url)
            }

            await MainActor.run {
                guard !Task.isCancelled, self.url == url else { return }
                self.result = imageInfo
            }
        } catch {
            Logger.warning(Strings.image_failed_to_load(url, error))
        }
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension URL {

    var asImageAndSize: (Image, CGSize)? {
        return DecodedImageCache.shared.imageAndSize(for: self)
    }

}

/// Process-wide cache of decoded images keyed by local file and remote URLs.
///
/// Avoids repeated `UIImage(contentsOfFile:)` / `NSImage(contentsOfFile:)` calls
/// when the same URL is loaded many times (e.g. SwiftUI re-initialising a view's
/// `StateObject`). `NSCache` evicts entries automatically on memory pressure.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class DecodedImageCache {

    static let shared = DecodedImageCache()

    private let cache = NSCache<NSURL, Entry>()

    private init() {}

    func cachedImageAndSize(for url: URL) -> (Image, CGSize)? {
        if let hit = self.cache.object(forKey: url as NSURL) {
            return (hit.image, hit.size)
        }

        return nil
    }

    func cacheImageAndSize(_ imageAndSize: (Image, CGSize), for url: URL) {
        self.cache.setObject(Entry(image: imageAndSize.0, size: imageAndSize.1), forKey: url as NSURL)
    }

    func imageAndSize(for url: URL) -> (Image, CGSize)? {
        if let hit = self.cachedImageAndSize(for: url) {
            return hit
        }

        guard let decoded = Self.decode(url: url) else {
            return nil
        }

        self.cacheImageAndSize(decoded, for: url)

        return decoded
    }

    private static func decode(url: URL) -> (Image, CGSize)? {
        #if os(macOS)
        if let image = NSImage(contentsOfFile: url.path) {
            return (Image(nsImage: image), image.size)
        } else {
            return nil
        }
        #else
        if let image = UIImage(contentsOfFile: url.path) {
            return (Image(uiImage: image), image.size)
        } else {
            return nil
        }
        #endif
    }

    private final class Entry {
        let image: Image
        let size: CGSize

        init(image: Image, size: CGSize) {
            self.image = image
            self.size = size
        }
    }

}
