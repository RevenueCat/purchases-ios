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

    var body: some View {
        ColorSchemeRemoteImage(
            url: self.url,
            lowResUrl: self.lowResUrl,
            darkUrl: self.darkUrl,
            darkLowResUrl: self.darkLowResUrl,
            expectedSize: self.expectedSize,
            aspectRatio: self.aspectRatio,
            maxWidth: self.maxWidth,
            colorScheme: self.colorScheme
        ) { image, size in
            content(image, size)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct ColorSchemeRemoteImage<Content: View>: View {

    private var colorScheme: ColorScheme

    let url: URL
    let lowResUrl: URL?
    let darkUrl: URL?
    let darkLowResUrl: URL?
    let aspectRatio: CGFloat?
    let maxWidth: CGFloat?
    let expectedSize: CGSize?
    let content: (Image, CGSize) -> Content

    // Preferred method of loading images
    // Using @StateObject so SwiftUI manages the lifecycle and preserves across view updates

    @StateObject
    private var highResFileLoader: FileImageLoader

    @StateObject
    private var lowResFileLoader: FileImageLoader

    private var transition: AnyTransition {
        #if DEBUG
        if ProcessInfo.isRunningRevenueCatTests && self.url.isFileURL {
            // No transition for the load of the local image
            // This is used for paywall screenshot validation
            return .identity
        }
        #endif

        let loadedFromCache = highResFileLoader.wasLoadedFromCache || lowResFileLoader.wasLoadedFromCache
        if loadedFromCache {
            // No transition if image is fully loaded from cache
            return .identity
        } else {
            return .opacity.animation(Constants.defaultAnimation)
        }
    }

    var localImage: (Image, CGSize)? {
        guard url.isFileURL else {
            return nil
        }

        return url.asImageAndSize
    }

    init(
        url: URL,
        lowResUrl: URL? = nil,
        darkUrl: URL? = nil,
        darkLowResUrl: URL? = nil,
        expectedSize: CGSize? = nil,
        aspectRatio: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        colorScheme: ColorScheme,
        @ViewBuilder content: @escaping (Image, CGSize) -> Content
    ) {
        self.url = url
        self.lowResUrl = lowResUrl
        self.darkUrl = darkUrl
        self.darkLowResUrl = darkLowResUrl
        self.content = content
        self.aspectRatio = aspectRatio
        self.maxWidth = maxWidth
        self.expectedSize = expectedSize
        self.colorScheme = colorScheme

        let highResURL = Self.selectURL(
            lightURL: url,
            darkURL: darkUrl,
            for: colorScheme
        )

        let lowResURL = Self.selectURL(
            lightURL: lowResUrl,
            darkURL: darkLowResUrl ?? lowResUrl,
            for: colorScheme
        )

        _highResFileLoader = StateObject(wrappedValue: FileImageLoader(fileRepository: .shared, url: highResURL))
        _lowResFileLoader = StateObject(wrappedValue: FileImageLoader(fileRepository: .shared, url: lowResURL))
    }

    private static func selectURL(
        lightURL: URL?,
        darkURL: URL?,
        for colorScheme: ColorScheme
    ) -> URL? {
        switch colorScheme {
        case .dark:
            return darkURL ?? lightURL
        case .light:
            fallthrough
        @unknown default:
            return lightURL
        }
    }

    private var effectiveHighResURL: URL? {
        Self.selectURL(lightURL: self.url, darkURL: self.darkUrl, for: self.colorScheme)
    }

    private var effectiveLowResURL: URL? {
        Self.selectURL(lightURL: self.lowResUrl, darkURL: self.darkLowResUrl ?? self.lowResUrl, for: self.colorScheme)
    }

    var body: some View {
        Group {
            if let imageAndSize = self.localImage {
                content(imageAndSize.0, imageAndSize.1)
            } else if let value = self.highResFileLoader.result {
                content(value.0, value.1)
            } else if let value = lowResFileLoader.result {
                content(value.0, value.1)
            } else {
                if let expectedSize = self.expectedSize {
                    content(Image.clearImage(size: expectedSize), expectedSize)
                } else {
                    emptyView(error: nil)
                }
            }
        }
        .transition(self.transition)
        // Keep file loaders in sync with effective URLs as selection/color scheme changes.
        .onChangeOf(self.effectiveHighResURL) { newURL in
            self.highResFileLoader.updateURL(newURL)
        }
        .onChangeOf(self.effectiveLowResURL) { newURL in
            self.lowResFileLoader.updateURL(newURL)
        }
        // This cancels the previous task when the URL or color scheme change, ensuring a proper update of the UI
        .task(id: "\(self.url)\(self.colorScheme)") {
            #if DEBUG
            // Don't attempt to load if local image
            // This is used for paywall screenshot validation
            guard self.localImage == nil else {
                return
            }
            #endif

            // Start loading using the loader's internal task management
            // This avoids any task capturing the loaders
            highResFileLoader.startLoading()
            lowResFileLoader.startLoading()
        }
        .onDisappear {
            // Cancel loading when view disappears
            highResFileLoader.cancelLoading()
            lowResFileLoader.cancelLoading()
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

private extension Image {
    /// Returns a fully transparent SwiftUI Image of the given size.
    static func clearImage(size: CGSize) -> Image {
        #if os(iOS) || os(visionOS)
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
