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

    static var invokedIsBlockedAPIError = false
    static var stubbedIsBlockedAPIError = false
    static func isBlockedAPIError(_ error: Error?) -> Bool {
        Self.invokedIsBlockedAPIError = true
        return Self.stubbedIsBlockedAPIError
    }

    static var invokedBlockedHostFromError = false
    static var stubbedBlockedHostFromError: String?
    static func blockedHostFromError(_ error: Error?) -> String? {
        Self.invokedBlockedHostFromError = true
        return Self.stubbedBlockedHostFromError
    }

    static var invokedIsBlockedURL = false
    static var stubbedIsBlockedURL = false
    static func isBlockedURL(_ url: URL) -> Bool {
        Self.invokedIsBlockedURL = true
        return Self.stubbedIsBlockedURL
    }

    static var invokedResolvedHostFromURL = false
    static var stubbedResolvedHostFromURL: String?
    static func resolvedHost(fromURL url: URL) -> String? {
        Self.invokedResolvedHostFromURL = true
        return Self.stubbedResolvedHostFromURL
    }

    static func resetData() {
        Self.invokedIsBlockedAPIError = false
        Self.stubbedIsBlockedAPIError = false

        Self.invokedBlockedHostFromError = false
        Self.stubbedBlockedHostFromError = nil

        Self.invokedIsBlockedURL = false
        Self.stubbedIsBlockedURL = false

        Self.invokedResolvedHostFromURL = false
        Self.stubbedResolvedHostFromURL = nil
    }

}
