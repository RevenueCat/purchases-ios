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

import Combine
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
        if let image = loader.image {
            let uiImage = Image(uiImage: image)
            if let aspectRatio {
                uiImage
                    .fitToAspect(aspectRatio, contentMode: .fill)
                    .frame(maxWidth: self.maxWidth)
                    .transition(.opacity.animation(Constants.defaultAnimation))

            } else {
                uiImage
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 5 * 1000 * 1000, diskCapacity: 30 * 1000 * 1000)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var error: Error?
    private var cancellable: AnyCancellable?
    private let cache: URLCache

    init(url: URL, cache: URLCache = .shared) {
        self.cache = cache
        load(url: url)
    }

    deinit {
        cancellable?.cancel()
    }

    func load(url: URL) {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return UIImage(data: output.data)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.error = error
                    self?.image = nil
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] image in
                self?.image = image
                self?.error = nil
            })
    }

}
