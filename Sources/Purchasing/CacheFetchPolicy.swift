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

    /// Default behavior: returns the cache data if available and not stale, or fetches up-to-date data.
    case cachedOrFetched

    /// Default ``CacheFetchPolicy`` behavior.
    public static let `default`: Self = .cachedOrFetched

}
