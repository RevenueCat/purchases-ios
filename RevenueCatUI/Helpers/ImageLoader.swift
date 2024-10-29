//
//  ImageLoader.swift
//
//
//  Created by Andrés Boedo on 11/29/23.
//

import Foundation
import RevenueCat

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import SwiftUI

protocol URLSessionType {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

}

@MainActor
final class ImageLoader: ObservableObject {

    enum Error: Swift.Error, Equatable {

        case responseError(NSError)
        case badResponse(URLError)
        case invalidImage

    }

    typealias Value = Result<(image: Image, size: CGSize), Error>

    // We want to remember the URL used for a successful load, so we can avoid loading it again if we get asked for
    // the same URL.
    private var resultWithURL: ValueWithURL? {
        didSet {
            self.result = resultWithURL.map { result in
                result.map { (image: $0.image, size: $0.size) }
            }
        }
    }

    @Published
    private(set) var result: Value? {
        didSet {
            if let result {
                Logger.verbose(Strings.image_result(result.map { _ in () }))
            }
        }
    }

    private let urlSession: URLSessionType

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    convenience init() {
        self.init(urlSession: Purchases.paywallImageDownloadSession)
    }

    init(urlSession: URLSessionType) {
        self.urlSession = urlSession
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func load(url: URL) async {
        // Only reload if the new URL is different from the current one.
        if case let .success((_, _, currentUrl))? = resultWithURL,
           currentUrl == url {
            return
        }
        Logger.verbose(Strings.image_starting_request(url))

        // Reset previous image before loading new one
        self.resultWithURL = nil
        self.resultWithURL = await self.loadImage(url)
    }

    /// - Returns: `nil` if the Task was cancelled.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    private func loadImage(_ url: URL) async -> ValueWithURL? {
        do {
            let (data, response) = try await self
                .urlSession
                .data(for: .init(url: url, cachePolicy: .returnCacheDataElseLoad))

            do {
                try Task.checkCancellation()
            } catch {
                return nil
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                return .failure(.badResponse(.init(.badServerResponse)))
            }

            // Load images in a background thread
            return await Task<ValueWithURL, Never>
                .detached(priority: .medium) { data.toImage(url: url) }
                .value
        } catch let error {
            return .failure(.responseError(error as NSError))
        }
    }

}

extension URLSession: URLSessionType {}

private typealias ValueWithURL = Result<(image: Image, size: CGSize, url: URL), ImageLoader.Error>

private extension Data {

    func toImage(url: URL) -> ValueWithURL {
        #if os(macOS)
        if let image = NSImage(data: self) {
            return .success((.init(nsImage: image), image.size, url))
        } else {
            return .failure(.invalidImage)
        }
        #else
        if let image = UIImage(data: self) {
            return .success((.init(uiImage: image), image.size, url))
        } else {
            return .failure(.invalidImage)
        }
        #endif
    }

}
