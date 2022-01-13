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
    static var stubbedIsBlockedAPIErrorResult = false
    static func isBlockedAPIError(_ error: Error?) -> Bool {
        Self.invokedIsBlockedAPIError = true
        return Self.stubbedIsBlockedAPIErrorResult
    }

    static var invokedErrorWithBlockedHostFromError = false
    static var stubbedErrorWithBlockedHostFromErrorResult: DNSError?
    static func errorWithBlockedHostFromError(_ error: Error?) -> DNSError? {
        Self.invokedErrorWithBlockedHostFromError = true
        return Self.stubbedErrorWithBlockedHostFromErrorResult
    }

    static var invokedIsBlockedURL = false
    static var stubbedIsBlockedURLResult = false
    static func isBlockedURL(_ url: URL) -> Bool {
        Self.invokedIsBlockedURL = true
        return Self.stubbedIsBlockedURLResult
    }

    static var invokedResolvedHostFromURL = false
    static var stubbedResolvedHostFromURLResult: String?
    static func resolvedHost(fromURL url: URL) -> String? {
        Self.invokedResolvedHostFromURL = true
        return Self.stubbedResolvedHostFromURLResult
    }

    static func resetData() {
        Self.invokedIsBlockedAPIError = false
        Self.stubbedIsBlockedAPIErrorResult = false

        Self.invokedErrorWithBlockedHostFromError = false
        Self.stubbedErrorWithBlockedHostFromErrorResult = nil

        Self.invokedIsBlockedURL = false
        Self.stubbedIsBlockedURLResult = false

        Self.invokedResolvedHostFromURL = false
        Self.stubbedResolvedHostFromURLResult = nil
    }

}
