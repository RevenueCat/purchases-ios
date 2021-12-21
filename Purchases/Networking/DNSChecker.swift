//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DNSChecker.swift
//
//  Created by Joshua Liebowitz on 12/20/21.

import Foundation

enum DNSChecker {

    static let invalidHosts = Set(["0.0.0.0", "127.0.0.1"])

    static func isBlockedAPIError(_ error: Error?) -> Bool {
        guard let error = error else {
            return false
        }

        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain,
              nsError.code == NSURLErrorCannotConnectToHost else {
            return false
        }

        guard let failedURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL else {
            return false
        }

        return isBlockedURL(failedURL)
    }

    static func blockedHostFromError(_ error: Error?) -> String? {
        guard let failedURL = (error as NSError?)?.userInfo[NSURLErrorFailingURLErrorKey] as? URL else {
            return nil
        }

        return resolvedHost(fromURL: failedURL)
    }

    static func isBlockedURL(_ url: URL) -> Bool {
        guard let resolvedHostName = resolvedHost(fromURL: url) else {
            return false
        }

        return self.invalidHosts.contains(resolvedHostName)
    }

    static func resolvedHost(fromURL url: URL) -> String? {
        guard let name = url.host,
              let host = name.withCString({gethostbyname($0)}),
              host.pointee.h_length > 0 else {
                  return nil
              }
        var addr = in_addr()
        memcpy(&addr.s_addr, host.pointee.h_addr_list[0], Int(host.pointee.h_length))

        guard let remoteIPAsC = inet_ntoa(addr) else {
            return nil
        }

        let hostIP = String(cString: remoteIPAsC)
        return hostIP
    }

}
