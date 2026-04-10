//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowCdnFetcher.swift
//
//  Created by RevenueCat.

import Foundation

/// A closure that fetches compiled workflow JSON from a CDN URL.
///
/// - Parameters:
///   - cdnUrl: The CDN URL string to fetch from.
///   - completion: Called with the raw `Data` on success, or an `Error` on failure.
typealias WorkflowCdnFetch = @Sendable (String, @escaping (Result<Data, Error>) -> Void) -> Void
