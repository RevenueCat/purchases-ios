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
// swiftlint:disable missing_docs

import Combine
import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) && !os(watchOS) && canImport(WebKit) // For Paywalls V2

import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public final class WebBundleCacheCoordinator {
    static let shared = WebBundleCacheCoordinator()

    private let job: AnyCancellable

    init(
        events: AnyPublisher<WebBundleEvent, Never> = WebBundleEventBus.shared.publisher,
        websiteDataStoreIdentifier: () -> UUID = { return WebViewDataStoreIdentifierStore.identifier() }
    ) {
        self.job = events
            .removeDuplicates()
            .receive(on: DispatchQueue(label: "web-bundle-cache-coordinator"))
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .empty: break
                case .cacheClearRequested:
                    clearWebCache(for: websiteDataStoreIdentifier())
                case .receivedAssetURLs:
                    // Will do in a coming PR
                }
            }
    }

    private func clearWebCache(for storeID: UUID) {
        if #available(iOS 17.0, macOS 14.0, *) {
            Task {
                await WKWebsiteDataStore(forIdentifier: storeID)
                    .removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
            }
        }
    }
}

#endif
