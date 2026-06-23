//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InMemoryHTMLURLProtocol.swift
//
//  Created by RevenueCat.
//

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
final class InMemoryHTMLURLProtocol: URLProtocol {

    static let scheme = "purchaseshtml"

    private static let store = InMemoryHTMLURLStore()

    private var loadingTask: Task<Void, Never>?

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == Self.scheme
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = self.request.url else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        self.loadingTask = Task { [weak self] in
            guard let self else { return }

            guard let entry = Self.store.entry(for: url) else {
                self.client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
                return
            }

            let response = URLResponse(
                url: url,
                mimeType: entry.mimeType,
                expectedContentLength: entry.data.count,
                textEncodingName: nil
            )

            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: entry.data)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        self.loadingTask?.cancel()
    }

    static func cachedURL(for originalURL: URL) -> URL? {
        return self.store.cachedURL(for: originalURL)
    }

    static func store(data: Data, mimeType: String?, for originalURL: URL) -> URL {
        return self.store.store(data: data, mimeType: mimeType, for: originalURL)
    }

    static func clear() async {
        self.store.clear()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private class InMemoryHTMLURLStore: @unchecked Sendable {

    private var entries: [URL: Entry] = [:]
    private var cachedURLsByOriginalURL: [URL: URL] = [:]
    let lock = NSLock()

    func entry(for url: URL) -> Entry? {
        return lock.withLock {
            return self.entries[url]
        }
    }

    func cachedURL(for originalURL: URL) -> URL? {
        return lock.withLock {
            return self.cachedURLsByOriginalURL[originalURL]
        }
    }

    func store(data: Data, mimeType: String?, for originalURL: URL) -> URL {
        return lock.withLock {
            if let cachedURL = self.cachedURLsByOriginalURL[originalURL] {
                return cachedURL
            }

            let cachedURL = Self.cachedURL(for: originalURL)
            self.entries[cachedURL] = Entry(data: data, mimeType: mimeType)
            self.cachedURLsByOriginalURL[originalURL] = cachedURL

            return cachedURL
        }
    }

    func clear() {
        return lock.withLock {
            self.entries = [:]
            self.cachedURLsByOriginalURL = [:]
        }
    }

    private static func cachedURL(for originalURL: URL) -> URL {
        let key = originalURL.absoluteString.asData.sha256String
        let filename = originalURL.lastPathComponent.isEmpty
            ? "index"
            : originalURL.lastPathComponent

        return URL(string: "\(InMemoryHTMLURLProtocol.scheme)://cached/\(key)/\(filename)").unsafelyUnwrapped
    }

}

private struct Entry: Sendable {
    let data: Data
    let mimeType: String?
}
