//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RemoteImage.swift
//  
//  Created by Nacho Soto on 7/19/23.

@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RemoteImage<Content: View>: View {

    @Environment(\.colorScheme)
    private var colorScheme

    let url: URL
    let lowResUrl: URL?
    let darkUrl: URL?
    let darkLowResUrl: URL?
    let aspectRatio: CGFloat?
    let maxWidth: CGFloat?
    let expectedSize: CGSize?
    let content: (Image, CGSize) -> Content

    // Preferred method of loading images

    @State
    private var highResCachedImage: (Image, CGSize)?

    @State
    private var lowResCachedImage: (Image, CGSize)?

    // Legacy method of loading images

    @StateObject
    private var highResLoader: ImageLoader = .init()

    @StateObject
    private var lowResLoader: ImageLoader = .init()

    var fetchLowRes: Bool {
        lowResUrl != nil
    }

    private var transition: AnyTransition {
        #if DEBUG
        if ProcessInfo.isRunningRevenueCatTests && self.url.isFileURL {
            // No transition for the load of the local image
            // This is used for paywall screenshot validation
            return .identity
        }
        #endif

        if self.cachedImageInfo != nil {
            // No transition if image is fully loaded from cache
            return .identity
        } else {
            return .opacity.animation(Constants.defaultAnimation)
        }
    }

    init(
        url: URL,
        lowResUrl: URL? = nil,
        darkUrl: URL? = nil,
        darkLowResUrl: URL? = nil,
        expectedSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image, CGSize) -> Content
    ) {
        self.url = url
        self.lowResUrl = lowResUrl
        self.darkUrl = darkUrl
        self.darkLowResUrl = darkLowResUrl
        self.content = content
        self.aspectRatio = nil
        self.maxWidth = nil
        self.expectedSize = expectedSize
    }

    init(
        url: URL,
        lowResUrl: URL? = nil,
        darkUrl: URL? = nil,
        darkLowResUrl: URL? = nil,
        aspectRatio: CGFloat? = nil,
        maxWidth: CGFloat? = nil
    ) where Content == AnyView {
        self.url = url
        self.lowResUrl = lowResUrl
        self.darkUrl = darkUrl
        self.darkLowResUrl = darkLowResUrl
        self.maxWidth = maxWidth
        self.aspectRatio = aspectRatio
        self.expectedSize = nil
        self.content = { (image, _) in
            if let aspectRatio {
                return AnyView(
                    image
                        .fitToAspect(aspectRatio, contentMode: .fill)
                        .frame(maxWidth: maxWidth)
                        .accessibilityHidden(true)
                )
            } else {
                return AnyView(
                    image
                        .resizable()
                        .accessibilityHidden(true)
                )
            }
        }
    }

    var localImage: (Image, CGSize)? {
        guard url.isFileURL else {
            return nil
        }

        return url.asImageAndSize
    }

    var cachedImageInfo: (Image, CGSize)? {
        let fullResUrl: URL
        let lowResUrl: URL?

        switch self.colorScheme {
        case .dark:
            fullResUrl = self.darkUrl ?? self.url
            lowResUrl = self.darkLowResUrl ?? self.lowResUrl
        case .light:
            fallthrough
        @unknown default:
            fullResUrl = self.darkUrl ?? self.url
            lowResUrl = self.darkLowResUrl ?? self.lowResUrl
        }

        let fileRepository = FileRepository()
        let fullResCachedUrl = fileRepository.getCachedFileURL(for: fullResUrl)
        let lowResCachedUrl = lowResUrl.flatMap { fileRepository.getCachedFileURL(for: $0) }

        let cachedUrl = fullResCachedUrl ?? lowResCachedUrl

        return cachedUrl?.asImageAndSize
    }

    var body: some View {
        Group {
            if let imageAndSize = self.localImage {
                content(imageAndSize.0, imageAndSize.1)
            // Preferred method
            } else if let imageAndSize = self.cachedImageInfo {
                content(imageAndSize.0, imageAndSize.1)
            // Legacy method
            } else if case let .success(result) = highResLoader.result {
                content(result.image, result.size)
            } else if case let .success(result) = lowResLoader.result {
                content(result.image, result.size)
            } else if case let .failure(highResError) = highResLoader.result {
                if !fetchLowRes {
                    emptyView(error: highResError)
                } else if case .failure = lowResLoader.result {
                    emptyView(error: highResError)
                } else {
                    emptyView(error: nil)
                }
            // Empty state
            } else {
                if let expectedSize = self.expectedSize {
                    content(Image.clearImage(size: expectedSize), expectedSize)
                } else {
                    emptyView(error: nil)
                }
            }
        }
        .transition(self.transition)
        .task(id: self.url) { // This cancels the previous task when the URL changes.
            #if DEBUG
            // Don't attempt to load if local image
            // This is used for paywall screenshot validation
            guard self.localImage == nil else {
                return
            }
            #endif

            switch self.colorScheme {
            case .dark:
                await loadImages(
                    url: self.darkUrl ?? self.url,
                    lowResUrl: self.darkLowResUrl ?? self.lowResUrl
                )
            case .light:
                fallthrough
            @unknown default:
                await loadImages(
                    url: self.url,
                    lowResUrl: self.lowResUrl
                )
            }
        }
    }

    private func loadImages(url: URL, lowResUrl: URL?) async {
        if fetchLowRes, let lowResLoc = lowResUrl {
            async let lowResLoad: Void = lowResLoader.load(url: lowResLoc)
            async let highResLoad: Void = highResLoader.load(url: url)
            _ = await (lowResLoad, highResLoad)
        } else {
            await highResLoader.load(url: url)
        }
    }

    @ViewBuilder
    private func emptyView(error: Error?) -> some View {
        let placeholderView = Rectangle()
            .hidden()

        Group {
            if let aspectRatio {
                placeholderView
                    .aspectRatio(aspectRatio, contentMode: .fit)
            } else {
                placeholderView
            }
        }
        .frame(maxWidth: self.maxWidth)
        .overlay {
            Group {
                if let error {
                    DebugErrorView("Error loading image from '\(self.url)': \(error)", releaseBehavior: .emptyView)
                        .font(.footnote)
                        .textCase(.none)
                }
            }
        }
    }

}

private extension URL {

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

#if os(iOS) || os(tvOS) || os(watchOS)
import SwiftUI
import UIKit
private typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
import SwiftUI
private typealias PlatformImage = NSImage
#endif

private extension Image {
    /// Returns a fully transparent SwiftUI Image of the given size.
    static func clearImage(size: CGSize) -> Image {
        #if os(iOS)
        let renderer = UIGraphicsImageRenderer(size: size)
        let uiImage = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return Image(uiImage: uiImage)

        #elseif os(tvOS) || os(watchOS)
        // Fallback for tvOS/watchOS: create a blank UIImage
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return Image(uiImage: uiImage ?? UIImage())

        #elseif os(macOS)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        NSColor.clear.setFill()
        NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        nsImage.unlockFocus()
        return Image(nsImage: nsImage)
        #endif
    }
}
