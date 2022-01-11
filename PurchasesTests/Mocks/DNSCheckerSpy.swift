//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DNSCheckerSpy.swift
//
//  Created by Juanpe Catalán on 11/1/22.

import Foundation
@testable import RevenueCat

enum DNSCheckerSpy: DNSCheckerType {

    static var isBlockedAPIErrorCalled: Bool = false
    static func isBlockedAPIError(_ error: Error?) -> Bool {
        Self.isBlockedAPIErrorCalled = true
        return DNSChecker.isBlockedAPIError(error)
    }

    static var blockedHostFromErrorCalled: Bool = false
    static func blockedHostFromError(_ error: Error?) -> String? {
        Self.blockedHostFromErrorCalled = true
        return DNSChecker.blockedHostFromError(error)
    }

    static var isBlockedURLCalled: Bool = false
    static func isBlockedURL(_ url: URL) -> Bool {
        Self.isBlockedURLCalled = true
        return DNSChecker.isBlockedURL(url)
    }

    static var resolvedHostFromURLCalled: Bool = false
    static func resolvedHost(fromURL url: URL) -> String? {
        Self.resolvedHostFromURLCalled = true
        return DNSChecker.resolvedHost(fromURL: url)
    }

    static func resetData() {
        Self.isBlockedAPIErrorCalled = false
        Self.blockedHostFromErrorCalled = false
        Self.isBlockedURLCalled = false
        Self.resolvedHostFromURLCalled = false
    }

}
