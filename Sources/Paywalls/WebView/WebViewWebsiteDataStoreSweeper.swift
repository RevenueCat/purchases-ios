//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewWebsiteDataStoreSweeper.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/26.
//

import Foundation

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

    // swiftlint:disable duplicate_imports
#if compiler(>=6.0)
internal import WebKit
#else
import WebKit
#endif
    // swiftlint:enable duplicate_imports

#endif

enum WebViewWebsiteDataStoreSweeper {

    @MainActor
    static func sweepPendingStores() async {
        let pending = WebViewDataStoreIdentifierStore.pendingRemovalIdentifiers()
        guard !pending.isEmpty else { return }

        #if !os(tvOS) && !os(watchOS) && canImport(WebKit)
        if #available(iOS 17.0, macOS 14.0, *) {
            let existing = Set(await WKWebsiteDataStore.allDataStoreIdentifiers)
            let remaining = await WebBundleCacheCoordinator.sweep(
                pending: pending,
                existing: existing,
                remove: { identifier in
                    await Self.removeStore(for: identifier)
                }
            )
            WebViewDataStoreIdentifierStore.keepPendingOnly(remaining)
            return
        }
        #endif

        WebViewDataStoreIdentifierStore.keepPendingOnly([])
    }

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    private static func removeStore(for identifier: UUID) async -> Bool {
        do {
            try await WKWebsiteDataStore.remove(forIdentifier: identifier)
            return true
        } catch {
            Logger.debug(Strings.paywalls.web_view_data_store_removal_failed(identifier, error))
            return false
        }
    }

#endif

}
