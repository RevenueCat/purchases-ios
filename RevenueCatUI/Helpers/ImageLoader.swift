//
//  ImageLoader.swift
//
//
//  Created by Andrés Boedo on 11/29/23.
//

#if canImport(UIKit)

import Foundation
import RevenueCat
import UIKit

protocol URLSessionType {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

}

@MainActor
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class ImageLoader: ObservableObject {

    enum Error: Swift.Error, Equatable {

        case responseError(NSError)
        case badResponse(URLError)
        case invalidImage

    }

    typealias Value = Result<UIImage, Error>

    @Published
    private(set) var result: Value? {
        didSet {
            if let result {
                Logger.verbose(Strings.image_result(result))
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

        self.result = await self.loadImage(url)
    }

    /// - Returns: `nil` if the Task was cancelled.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    private func loadImage(_ url: URL) async -> Value? {
        do {
            let (data, response) = try await self
                .urlSession
                .data(for: .init(url: url, cachePolicy: .returnCacheDataElseLoad))

            try? Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(.badResponse(.init(.badServerResponse)))
            }

            return await Task<Value, Never>
                .detached(priority: .utility) {
                    // Load images in a background thread
                    if let image = UIImage(data: data) {
                        return .success(image)
                    } else {
                        return .failure(.invalidImage)
                    }
                }
                .value
        } catch let error {
            return .failure(.responseError(error as NSError))
        }
    }

}

extension URLSession: URLSessionType {}

#endif
