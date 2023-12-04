//
//  ImageLoader.swift
//
//
//  Created by Andrés Boedo on 11/29/23.
//

import Combine
import Foundation
import UIKit

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
    private let urlSessionConfiguration: URLSessionConfiguration

    init(url: URL, cache: URLCache) {
        self.cache = cache
        self.urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.urlCache = cache
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
