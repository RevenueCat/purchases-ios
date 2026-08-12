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

internal import WebKit

#endif

final class WebBundleCacheCoordinator {
    private let job: AnyCancellable?

    #if !os(tvOS) && !os(watchOS) && canImport(WebKit)

    init(
        events: AnyPublisher<WebBundleEvent, Never> = WebBundleEventBus.shared.publisher,
        clearWebsiteData: @escaping () -> Void = WebBundleCacheCoordinator.clearWebsiteData
    ) {
        self.job = events
            .receive(on: DispatchQueue(label: "com.revenuecat.web-bundle-cache-coordinator"))
            .sink { event in
                switch event {
                case .empty:
                    break
                case .receivedAssetURLs:
                    break // Will do in a future PR
                case .cacheClearRequested:
                    clearWebsiteData()
                }
            }
    }

    private static func clearWebsiteData() {
        if let id = WebViewDataStoreIdentifierStore.clearIdentifier() {
            Task { @MainActor in
                clearWebKitStore(for: id)
            }
        }
    }

    /// Attempts to remove the whole store but falls back to wiping the data it contains if removal fails
    @MainActor
    private static func clearWebKitStore(for id: UUID) {
        if #available(iOS 17.0, macOS 14.0, *) {
            WKWebsiteDataStore.remove(forIdentifier: id) { error in
                if error != nil {
                    WKWebsiteDataStore(forIdentifier: id)
                        .removeData(
                            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                            modifiedSince: .distantPast
                        ) {}
                }
            }
        }
    }

    #else

    init() {
        self.job = nil
    }

    #endif

}
