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

    @StateObject private var loader: ImageLoader
    private let cache: URLCache

    let url: URL
    let aspectRatio: CGFloat?
    let maxWidth: CGFloat?

    init(url: URL, aspectRatio: CGFloat? = nil, maxWidth: CGFloat? = nil, cache: URLCache = .imageCache) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.maxWidth = maxWidth
        self.cache = cache
        self._loader = StateObject(wrappedValue: ImageLoader(url: url, cache: cache))
    }

    var body: some View {
        if let loadedUIImage = loader.image {
            let image = Image(uiImage: loadedUIImage)
            if let aspectRatio {
                image
                    .fitToAspect(aspectRatio, contentMode: .fill)
                    .frame(maxWidth: self.maxWidth)
                    .transition(.opacity.animation(Constants.defaultAnimation))

            } else {
                image
                    .resizable()
                    .transition(.opacity.animation(Constants.defaultAnimation))
            }
        } else {
            Group {
                if let aspectRatio {
                    self.placeholderView
                        .aspectRatio(aspectRatio, contentMode: .fit)
                } else {
                    self.placeholderView
                }
            }
            .frame(maxWidth: self.maxWidth)
            .transition(.opacity.animation(Constants.defaultAnimation))
            .overlay {
                Group {
                    if let error = loader.error {
                        DebugErrorView("Error loading image from '\(self.url)': \(error)", releaseBehavior: .emptyView)
                            .font(.footnote)
                            .textCase(.none)
                    }
                }
            }

        }
    }

    private var placeholderView: some View {
        Rectangle()
            .hidden()
    }

}
