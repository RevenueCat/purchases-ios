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
    let url: URL?

    private var loadTask: Task<Void, Never>?

    @MainActor
    init(fileRepository: FileRepository, url: URL?) {
        self.fileRepository = fileRepository
        self.url = url

        self.loadFromCache(url: url)
    }

    deinit {
        loadTask?.cancel()
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

    private(set) var wasLoadedFromCache: Bool = false

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

    /// Start loading without requiring external task management.
    /// The loader manages its own task lifecycle.
    /// - Parameter url: Optional URL override. If provided and different from current,
    /// cancels current loading and starts new.
    @MainActor
    func startLoading(url: URL? = nil) {
        let targetUrl = url ?? self.url

        // If a different URL is requested, cancel current and reload
        if let url = url, url != self.url {
            cancelLoading()
            result = nil
        }

        guard loadTask == nil, result == nil else { return }
        guard let targetUrl = targetUrl else { return }

        // Capture only what we need - avoid capturing self during the await
        let fileRepository = self.fileRepository

        loadTask = Task { [weak self] in
            guard !Task.isCancelled else { return }

            do {
                // Don't hold strong reference to self during network await
                let cachedURL = try await fileRepository.generateOrGetCachedFileURL(
                    for: targetUrl, withChecksum: nil
                )

                guard !Task.isCancelled else { return }

                let imageInfo = cachedURL.asImageAndSize

                await MainActor.run { [weak self] in
                    guard !Task.isCancelled else { return }
                    self?.result = imageInfo
                }
            } catch {
                Logger.debug(Strings.image_result(.failure(.responseError(error as NSError))))
            }
        }
    }

    /// Cancel any ongoing loading
    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }

}

extension URL {

    var asImageAndSize: (Image, CGSize)? {
        #if os(macOS)
        if let image = NSImage(contentsOfFile: self.path) {
            return (Image(nsImage: image), image.size)
        } else {
            return nil
        }
        #else
        if let image = UIImage(contentsOfFile: self.path) {
            return (Image(uiImage: image), image.size)
        } else {
            return nil
        }
        #endif
    }

}
