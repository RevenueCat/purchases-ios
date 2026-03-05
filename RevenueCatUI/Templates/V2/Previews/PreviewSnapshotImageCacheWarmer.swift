//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PreviewSnapshotImageCacheWarmer.swift
//
//  Created by RevenueCat on 3/5/26.
//

#if !os(tvOS) // For Paywalls V2

#if DEBUG

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PreviewSnapshotImageCacheWarmer {

    /// Ensures image previews render deterministically on first frame in snapshot environments.
    static func prepareForPaywallsV2PreviewsIfNeeded() {
        guard ProcessInfo.isRunningForPreviews else { return }

        self.prepareForSnapshot(urls: Self.defaultPaywallsV2PreviewURLs)
    }

    /// Stubs remote image requests and prewarms `FileRepository.shared` for the given urls.
    static func prepareForSnapshot(urls: [URL]) {
        let urlsToWarm = self.consumeNewRemoteURLs(from: urls)
        guard !urlsToWarm.isEmpty else { return }

        self.installProtocolIfNeeded()
        self.prewarmSynchronously(urls: urlsToWarm)
    }

    private static func prewarmSynchronously(urls: [URL]) {
        let semaphore = DispatchSemaphore(value: 0)

        Task.detached(priority: .userInitiated) {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = try? await FileRepository.shared.generateOrGetCachedFileURL(
                            for: url,
                            withChecksum: nil
                        )
                    }
                }
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 5)
    }

    private static func installProtocolIfNeeded() {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard !self.didInstallProtocol else { return }

        URLProtocol.registerClass(PreviewSnapshotImageURLProtocol.self)
        self.didInstallProtocol = true
    }

    private static func consumeNewRemoteURLs(from urls: [URL]) -> [URL] {
        self.lock.lock()
        defer { self.lock.unlock() }

        let incoming = Set(urls.filter { $0.isRemoteSnapshotImageURL })
        let newURLs = incoming.subtracting(self.warmedURLs)
        self.warmedURLs.formUnion(newURLs)

        return Array(newURLs)
    }

    private static let lock = NSLock()
    private static var didInstallProtocol = false
    private static var warmedURLs: Set<URL> = []

    // Source URLs currently used by Paywalls V2 previews.
    // These are prewarmed so RemoteImage can resolve from disk cache immediately.
    private static let defaultPaywallsV2PreviewURLs: [URL] = [
        URL(string: "https://assets.pawwalls.com/954459_1701163461.jpg")!,
        URL(string: "https://assets.pawwalls.com/954459_1710750526.jpeg")!,
        URL(string: "https://assets.pawwalls.com/1172568_1741034533.heic")!,
        URL(string: "https://assets.pawwalls.com/1172568_1734493671.heic")!,
        URL(string: "https://assets.pawwalls.com/1151049_1736611979.heic")!,
        URL(string: "https://icons.pawwalls.com/icons/pizza.heic")!,
        URL(string: "https://icons.pawwalls.com/icons/lock.heic")!,
        URL(string: "https://icons.pawwalls.com/icons/bell.heic")!,
        URL(string: "https://icons.pawwalls.com/icons/star.heic")!,
        URL(string: "https://icons.pawwalls.com/icons/pizza.svg")!,
        URL(string: "https://icons.pawwalls.com/icons/lock.svg")!,
        URL(string: "https://icons.pawwalls.com/icons/bell.svg")!,
        URL(string: "https://icons.pawwalls.com/icons/star.svg")!
    ]

}

private final class PreviewSnapshotImageURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else {
            return false
        }

        return url.isRemoteSnapshotImageURL
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let client = self.client else { return }

        let response = HTTPURLResponse(
            url: self.request.url ?? URL(string: "https://assets.pawwalls.com/stub.png")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "Content-Type": "image/png",
                "Cache-Control": "public, max-age=31536000"
            ]
        )!

        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowedInMemoryOnly)
        client.urlProtocol(self, didLoad: Self.stubPNGData)
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    // 2x2 transparent PNG.
    // We intentionally return raster bytes even for `.svg` URLs so platform decoders
    // can render deterministically in snapshot infrastructure.
    private static let stubPNGData = Data(base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAD0lEQVR4nGP8z8DAwMDAAAAKAgEBrGv0XwAAAABJRU5ErkJggg=="
    )!

}

private extension URL {

    var isRemoteSnapshotImageURL: Bool {
        guard let scheme = self.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = self.host?.lowercased(),
              Self.snapshotImageHosts.contains(host) else {
            return false
        }

        let `extension` = self.pathExtension.lowercased()
        return Self.snapshotImageExtensions.contains(`extension`)
    }

    private static let snapshotImageHosts: Set<String> = [
        "assets.pawwalls.com",
        "icons.pawwalls.com",
        "assets.revenuecat.com"
    ]

    private static let snapshotImageExtensions: Set<String> = [
        "svg",
        "png",
        "jpg",
        "jpeg",
        "webp",
        "heic"
    ]

}

#endif

#endif
