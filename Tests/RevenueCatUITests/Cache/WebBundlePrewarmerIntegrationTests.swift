//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundlePrewarmerIntegrationTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/17/26.

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && !os(watchOS) && canImport(WebKit)

/// Hits the production `WKWebView` load path. Completing well under the 15s load timeout means
/// navigation finished (or failed), not that we sat on the timeout.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class WebBundlePrewarmerIntegrationTests: TestCase {

    private static let completionLimit: TimeInterval = 10

    func testProductionPrewarmerLoadsAboutBlank() async {
        let prewarmer = WebBundlePrewarmer()
        let start = Date()

        await prewarmer.prewarm([
            .init(url: Self.aboutBlank, checksum: nil)
        ])

        XCTAssertLessThan(Date().timeIntervalSince(start), Self.completionLimit)
        XCTAssertEqual(self.loadLogCount, 1, self.loadLogDescription)
    }

    func testProductionPrewarmerLoadsABatchOfLocalPages() async {
        let prewarmer = WebBundlePrewarmer(maxConcurrentLoads: 3)
        let start = Date()

        await prewarmer.prewarm([
            .init(url: Self.aboutBlank, checksum: nil),
            .init(url: Self.dataURL("one"), checksum: nil),
            .init(url: Self.dataURL("two"), checksum: nil),
            .init(url: Self.dataURL("three"), checksum: nil)
        ])

        XCTAssertLessThan(Date().timeIntervalSince(start), Self.completionLimit)
        XCTAssertEqual(self.loadLogCount, 4, self.loadLogDescription)
    }

}

@available(iOS 17.0, macOS 14.0, *)
private extension WebBundlePrewarmerIntegrationTests {

    var loadLogCount: Int {
        return self.logger.messages.filter { Self.isLoadLog($0.message) }.count
    }

    var loadLogDescription: String {
        return "Logged: \(self.logger.messages.map(\.message))"
    }

    static func isLoadLog(_ message: String) -> Bool {
        return message.contains("Paywalls V2 web_view successfully loaded:")
    }

    static var aboutBlank: URL {
        // about:blank avoids network/ATS flakiness seen with https base URLs in CI.
        // swiftlint:disable:next force_unwrapping
        return URL(string: "about:blank")!
    }

    static func dataURL(_ body: String) -> URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: "data:text/html,\(body)")!
    }

}

#endif
