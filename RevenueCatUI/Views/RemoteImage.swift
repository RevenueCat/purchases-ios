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
struct RemoteImage<Content: View>: View {

    let url: URL
    let lowResUrl: URL?
    let aspectRatio: CGFloat?
    let maxWidth: CGFloat?
    let content: (Image, CGSize) -> Content

    @StateObject
    private var highResLoader: ImageLoader = .init()

    @StateObject
    private var lowResLoader: ImageLoader = .init()

    var fetchLowRes: Bool {
        lowResUrl != nil
    }

    private let transition: AnyTransition = .opacity.animation(Constants.defaultAnimation)

    init(
        url: URL,
        lowResUrl: URL? = nil,
        @ViewBuilder content: @escaping (Image, CGSize) -> Content
    ) {
        self.url = url
        self.lowResUrl = lowResUrl
        self.content = content
        self.aspectRatio = nil
        self.maxWidth = nil
    }

    init(
        url: URL,
        lowResUrl: URL? = nil,
        aspectRatio: CGFloat? = nil,
        maxWidth: CGFloat? = nil
    ) where Content == AnyView {
        self.url = url
        self.lowResUrl = lowResUrl
        self.maxWidth = maxWidth
        self.aspectRatio = aspectRatio
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
        Group {
            if case let .success(result) = highResLoader.result {
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
            } else {
                emptyView(error: nil)
            }
        }
        .transition(self.transition)
        .task(id: self.url) { // This cancels the previous task when the URL changes.
            await loadImages()
        }
    }

    private func loadImages() async {
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
