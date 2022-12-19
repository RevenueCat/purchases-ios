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

protocol DNSCheckerType {

    static func isBlockedAPIError(_ error: Error?) -> Bool
    static func errorWithBlockedHostFromError(_ error: Error?) -> NetworkError?
    static func isBlockedURL(_ url: URL) -> Bool
    static func resolvedHost(fromURL url: URL) -> String?

}

enum DNSChecker: DNSCheckerType {

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

    static func errorWithBlockedHostFromError(_ error: Error?) -> NetworkError? {
        guard self.isBlockedAPIError(error),
              let nsError = error as NSError?,
              let failedURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL else {
            return nil
        }

        let host = self.resolvedHost(fromURL: failedURL)
        return .dnsError(failedURL: failedURL, resolvedHost: host)
    }

    static func isBlockedURL(_ url: URL) -> Bool {
        guard let resolvedHostName = self.resolvedHost(fromURL: url) else {
            return false
        }

        Logger.debug(Strings.network.failing_url_resolved_to_host(url: url,
                                                                  resolvedHost: resolvedHostName))

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
