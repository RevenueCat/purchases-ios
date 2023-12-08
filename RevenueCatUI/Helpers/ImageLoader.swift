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
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class ImageLoader: ObservableObject {

    enum Error: Swift.Error, Equatable {

        case responseError(NSError)
        case badResponse(URLError)
        case invalidImage

    }

    typealias Value = Result<Image, Error>

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
        Logger.verbose(Strings.image_starting_request(url))

        // Reset previous image before loading new one
        self.result = nil
        self.result = await self.loadImage(url)
    }

    /// - Returns: `nil` if the Task was cancelled.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    private func loadImage(_ url: URL) async -> Value? {
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
            return await Task<Value, Never>
                .detached(priority: .utility) { data.toImage() }
                .value
        } catch let error {
            return .failure(.responseError(error as NSError))
        }
    }

}

extension URLSession: URLSessionType {}

private extension Data {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func toImage() -> ImageLoader.Value {
        #if os(macOS)
        if let image = NSImage(data: self) {
            return .success(.init(nsImage: image))
        } else {
            return .failure(.invalidImage)
        }
        #else
        if let image = UIImage(data: self) {
            return .success(.init(uiImage: image))
        } else {
            return .failure(.invalidImage)
        }
        #endif
    }

}
