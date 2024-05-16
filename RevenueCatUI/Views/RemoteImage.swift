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

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct RemoteImage: View {

    let url: URL
    let aspectRatio: CGFloat?
    let maxWidth: CGFloat?
    let lowResSuffix: String?

    var fetchLowRes: Bool {
        return false
        // TODO: Replace `return false` with the following when the back end is ready
        // lowResSuffix != nil
    }

    @StateObject
    private var highResLoader: ImageLoader = .init()

    @StateObject
    private var lowResLoader: ImageLoader = .init()

    init(url: URL, aspectRatio: CGFloat? = nil, maxWidth: CGFloat? = nil, lowResSuffix: String? = "_low_res") {
        self.url = url
        self.aspectRatio = aspectRatio
        self.maxWidth = maxWidth
        self.lowResSuffix = lowResSuffix
    }

    var body: some View {
        Group {
            if case let .success(image) = highResLoader.result {
                displayImage(image)
            } else if case let .success(image) = lowResLoader.result {
                displayImage(image)
            } else if case let .failure(highResError) = highResLoader.result {
                if !fetchLowRes {
                    emptyView(error: highResError)
                } else if case .failure = lowResLoader.result {
                    emptyView(error: highResError)
                } else {
                    emptyView(error: nil)
                }
            } else {
                emptyView(error: nil)
            }
        }
        .transition(Self.transition)
        .task(id: self.url) { // This cancels the previous task when the URL changes.
            await loadImages()
        }
    }

    private func displayImage(_ image: Image) -> some View {
            if let aspectRatio {
                return AnyView(
                    image
                        .fitToAspect(aspectRatio, contentMode: .fill)
                        .frame(maxWidth: self.maxWidth)
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

    private func loadImages() async {
        if fetchLowRes, let suffix = lowResSuffix {
            let lowResURL = url.deletingLastPathComponent()
                                .appendingPathComponent(url.deletingPathExtension().lastPathComponent + suffix)
                                .appendingPathExtension(url.pathExtension)

            async let lowResLoad: Void = lowResLoader.load(url: lowResURL)
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

    private static let transition: AnyTransition = .opacity.animation(Constants.defaultAnimation)

}
