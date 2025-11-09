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

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.result = imageInfo
            }
        } catch {

        }
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
