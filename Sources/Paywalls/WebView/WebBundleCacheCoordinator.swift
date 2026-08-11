//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleCacheCoordinator.swift
//
//  Created by Jacob Zivan Rakidzich on 8/11/26.
//

import Combine
import Foundation

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

import WebKit

final class WebBundleCacheCoordinator {

    static let shared = WebBundleCacheCoordinator()

    private let job: AnyCancellable

    static func initializeIfAvailable() {
        _ = Self.shared
    }

    init(
        events: AnyPublisher<WebBundleEvent, Never> = WebBundleEventBus.shared.publisher,
        websiteDataStoreIdentifier: () -> UUID = { WebViewDataStoreIdentifierStore.identifier() },
        clearWebsiteData: @escaping (UUID) -> Void = WebBundleCacheCoordinator.clearWebsiteData
    ) {
        let identifier = websiteDataStoreIdentifier()
        self.job = events
            .receive(on: DispatchQueue(label: "com.revenuecat.web-bundle-cache-coordinator"))
            .sink { event in
                switch event {
                case .empty, .receivedAssetURLs:
                    break
                case .cacheClearRequested:
                    clearWebsiteData(identifier)
                }
            }
    }

    private static func clearWebsiteData(for storeIdentifier: UUID) {
        if #available(iOS 17.0, macOS 14.0, *) {
            Task {
                await WKWebsiteDataStore(forIdentifier: storeIdentifier)
                    .removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
            }
        }
    }

}

#else

enum WebBundleCacheCoordinator {

    static func initializeIfAvailable() {}

}

#endif
