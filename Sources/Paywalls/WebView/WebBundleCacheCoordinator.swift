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

import Foundation

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

internal import WebKit

#endif

final class WebBundleCacheCoordinator {
    typealias FunctionWithCallback = (@escaping () -> Void) -> Void

    let clearData: FunctionWithCallback

    init(clearData: @escaping FunctionWithCallback) {
        self.clearData = clearData
    }

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

    static let shared = WebBundleCacheCoordinator(clearData: WebBundleCacheCoordinator.clearWebsiteData(completion:))

    static func clearWebsiteData(completion: @escaping () -> Void) {
        Task {
            await clearWebsiteData()
            completion()
        }
    }

    static func clearWebsiteData() async {
        if let id = WebViewDataStoreIdentifierStore.clearIdentifier() {
            await clearWebKitStore(for: id)
        }
    }

    /// Attempts to remove the whole store but falls back to wiping the data it contains if removal fails
    @MainActor
    private static func clearWebKitStore(for id: UUID) async {
        if #available(iOS 17.0, macOS 14.0, *) {
            await withCheckedContinuation { @MainActor continuation in
                WKWebsiteDataStore.remove(forIdentifier: id) { error in
                    if error != nil {
                        WKWebsiteDataStore(forIdentifier: id)
                            .removeData(
                                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                modifiedSince: .distantPast
                            ) { continuation.resume() }
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }

    #else

    static let shared = WebBundleCacheCoordinator(clearData: { $0() })

    #endif

}
