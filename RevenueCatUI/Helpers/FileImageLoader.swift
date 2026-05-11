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
    private(set) var url: URL?

    @MainActor
    init(fileRepository: FileRepository, url: URL?) {
        self.fileRepository = fileRepository
        self.url = url
        self.loadFromCache(url: url)
    }

    typealias Value = (image: Image, size: CGSize)

    @MainActor
    private func loadFromCache(url: URL?) {
        guard let url = url else {
            return
        }

        let result = fileRepository.getCachedFileURL(
            for: url,
            withChecksum: nil
        )?.asImageAndSize

        self.wasLoadedFromCache = result != nil
        self.result = result
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
        if await self.result != nil {
            return
        }

        guard let url = self.url else {
            return
        }

        do {
            let imageInfo = try await self.fileRepository.generateOrGetCachedFileURL(
                for: url, withChecksum: nil
            ).asImageAndSize

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
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

/// Process-wide, memory-bounded cache of decoded images keyed by file URL.
///
/// Avoids repeated `UIImage(contentsOfFile:)` / `NSImage(contentsOfFile:)` calls
/// when the same URL is loaded many times (e.g. SwiftUI re-initialising a view's
/// `StateObject`). `NSCache` evicts entries automatically on memory pressure.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class DecodedImageCache {

    static let shared = DecodedImageCache()

    private let cache = NSCache<NSURL, Entry>()
    private let queue = DispatchQueue(label: "com.revenuecat.DecodedImageCache", attributes: .concurrent)

    private init() {}

    func imageAndSize(for url: URL) -> (Image, CGSize)? {
        let key = url as NSURL

        if let hit = self.queue.sync(execute: { self.cache.object(forKey: key) }) {
            return (hit.image, hit.size)
        }

        guard let decoded = Self.decode(url: url) else {
            return nil
        }

        self.queue.async(flags: .barrier) {
            self.cache.setObject(Entry(image: decoded.0, size: decoded.1), forKey: key)
        }

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
