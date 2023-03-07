//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CacheFetchPolicy.swift
//
//  Created by Nacho Soto on 5/24/22.

/// Specifies the behavior for a caching API.
@objc(RCCacheFetchPolicy)
public enum CacheFetchPolicy: Int {

    /// Returns values from the cache, or throws an error if not available.
    case fromCacheOnly

    /// Always fetch the most up-to-date data.
    case fetchCurrent

    /// Returns the cached data if available and not stale, or fetches up-to-date data.
    /// - Warning: if the cached data is stale, and fetching up-to-date data fails (if offline, for example)
    /// an error will be returned instead of the outdated cached data.
    case notStaleCachedOrFetched

    /// Default behavior: returns the cached data if available (even if stale), or fetches up-to-date data.
    case cachedOrFetched

    /// Default ``CacheFetchPolicy`` behavior.
    public static let `default`: Self = .cachedOrFetched

}

extension CacheFetchPolicy: Sendable {}
