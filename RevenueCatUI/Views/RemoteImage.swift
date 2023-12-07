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

    @StateObject
    private var loader: ImageLoader = .init()

    init(url: URL, aspectRatio: CGFloat? = nil, maxWidth: CGFloat? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.maxWidth = maxWidth
    }

    var body: some View {
        Group {
            switch self.loader.result {
            case .none:
                self.emptyView(nil)

            case let .success(image):
                let image = Image(uiImage: image)

                if let aspectRatio {
                    image
                        .fitToAspect(aspectRatio, contentMode: .fill)
                        .frame(maxWidth: self.maxWidth)

                } else {
                    image
                        .resizable()
                }

            case let .failure(error):
                self.emptyView(error)
            }
        }
        .transition(Self.transition)
        .task(id: self.url) {
            await self.loader.load(url: self.url)
        }
    }

    @ViewBuilder
    private func emptyView(_ error: Error?) -> some View {
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
