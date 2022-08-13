//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockDNSChecker.swift
//
//  Created by Juanpe Catalán on 11/1/22.

import Foundation
@testable import RevenueCat

enum MockDNSChecker: DNSCheckerType {

    static let invokedIsBlockedAPIError: Atomic<Bool> = false
    static let stubbedIsBlockedAPIErrorResult: Atomic<Bool> = false
    static func isBlockedAPIError(_ error: Error?) -> Bool {
        Self.invokedIsBlockedAPIError.value = true
        return Self.stubbedIsBlockedAPIErrorResult.value
    }

    static let invokedErrorWithBlockedHostFromError: Atomic<Bool> = false
    static let stubbedErrorWithBlockedHostFromErrorResult: Atomic<NetworkError?> = nil
    static func errorWithBlockedHostFromError(_ error: Error?) -> NetworkError? {
        Self.invokedErrorWithBlockedHostFromError.value = true
        return Self.stubbedErrorWithBlockedHostFromErrorResult.value
    }

    static let invokedIsBlockedURL: Atomic<Bool> = false
    static let stubbedIsBlockedURLResult: Atomic<Bool> = false
    static func isBlockedURL(_ url: URL) -> Bool {
        Self.invokedIsBlockedURL.value = true
        return Self.stubbedIsBlockedURLResult.value
    }

    static let invokedResolvedHostFromURL: Atomic<Bool> = false
    static let stubbedResolvedHostFromURLResult: Atomic<String?> = nil
    static func resolvedHost(fromURL url: URL) -> String? {
        Self.invokedResolvedHostFromURL.value = true
        return Self.stubbedResolvedHostFromURLResult.value
    }

    static func resetData() {
        Self.invokedIsBlockedAPIError.value = false
        Self.stubbedIsBlockedAPIErrorResult.value = false

        Self.invokedErrorWithBlockedHostFromError.value = false
        Self.stubbedErrorWithBlockedHostFromErrorResult.value = nil

        Self.invokedIsBlockedURL.value = false
        Self.stubbedIsBlockedURLResult.value = false

        Self.invokedResolvedHostFromURL.value = false
        Self.stubbedResolvedHostFromURLResult.value = nil
    }

}
