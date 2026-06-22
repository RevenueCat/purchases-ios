//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewCapabilitiesTests.swift

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) && canImport(WebKit)

import WebKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebViewCapabilitiesTests: TestCase {

    private typealias NetworkAccess = PaywallComponent.WebViewCapabilities.NetworkAccess

    // MARK: - Content-blocking rules

    func testContentBlockingRulesAreNilWhenNetworkAccessAbsent() {
        XCTAssertNil(WebViewCapabilitiesConfiguration.contentBlockingRules(for: nil))
        XCTAssertNil(WebViewCapabilitiesConfiguration.contentRuleListIdentifier(for: nil))
    }

    func testContentBlockingRulesForEmptyDomainsBlocksEverything() throws {
        let rules = try XCTUnwrap(
            WebViewCapabilitiesConfiguration.contentBlockingRules(for: NetworkAccess(allowedDomains: []))
        )

        let parsed = try Self.parseRules(rules)
        XCTAssertEqual(parsed.count, 1)

        let trigger = try XCTUnwrap(parsed.first?["trigger"] as? [String: Any])
        XCTAssertEqual(trigger["url-filter"] as? String, ".*")
        XCTAssertNil(trigger["unless-domain"], "A block-all rule must not carry an unless-domain allow list")

        let action = try XCTUnwrap(parsed.first?["action"] as? [String: Any])
        XCTAssertEqual(action["type"] as? String, "block")
    }

    func testContentBlockingRulesForNilDomainsBlocksEverything() throws {
        // A `network_access` object present but with no `allowed_domains` array is still "present".
        let rules = try XCTUnwrap(
            WebViewCapabilitiesConfiguration.contentBlockingRules(for: NetworkAccess(allowedDomains: nil))
        )
        let trigger = try XCTUnwrap(try Self.parseRules(rules).first?["trigger"] as? [String: Any])
        XCTAssertNil(trigger["unless-domain"])
    }

    func testContentBlockingRulesAllowListsDomains() throws {
        let rules = try XCTUnwrap(
            WebViewCapabilitiesConfiguration.contentBlockingRules(
                for: NetworkAccess(allowedDomains: ["cdn.example.com", "api.example.com"])
            )
        )

        let trigger = try XCTUnwrap(try Self.parseRules(rules).first?["trigger"] as? [String: Any])
        let unlessDomain = try XCTUnwrap(trigger["unless-domain"] as? [String])
        XCTAssertEqual(Set(unlessDomain), ["api.example.com", "cdn.example.com"])
    }

    func testContentBlockingRulesAreValidJSON() throws {
        let rules = try XCTUnwrap(
            WebViewCapabilitiesConfiguration.contentBlockingRules(
                for: NetworkAccess(allowedDomains: ["a.example.com"])
            )
        )
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(rules.utf8)))
    }

    func testUnlessDomainOrderIsStableAndSorted() throws {
        let unsorted = NetworkAccess(allowedDomains: ["zeta.example.com", "alpha.example.com", "mid.example.com"])
        let rules = try XCTUnwrap(WebViewCapabilitiesConfiguration.contentBlockingRules(for: unsorted))

        let trigger = try XCTUnwrap(try Self.parseRules(rules).first?["trigger"] as? [String: Any])
        let unlessDomain = try XCTUnwrap(trigger["unless-domain"] as? [String])
        XCTAssertEqual(unlessDomain, ["alpha.example.com", "mid.example.com", "zeta.example.com"])
    }

    func testContentRuleListIdentifierIsDeterministicRegardlessOfInputOrder() {
        let first = WebViewCapabilitiesConfiguration.contentRuleListIdentifier(
            for: NetworkAccess(allowedDomains: ["b.example.com", "a.example.com"])
        )
        let second = WebViewCapabilitiesConfiguration.contentRuleListIdentifier(
            for: NetworkAccess(allowedDomains: ["a.example.com", "b.example.com"])
        )
        XCTAssertEqual(first, second)
        XCTAssertNotNil(first)
    }

    func testContentRuleListIdentifierForEmptyDomainsIsBlockAll() {
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.contentRuleListIdentifier(for: NetworkAccess(allowedDomains: [])),
            "rc-webview-block-all"
        )
    }

    // MARK: - Media capture decisions

    func testCameraGrantedOnlyWhenCameraTrue() {
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .camera,
                capabilities: PaywallComponent.WebViewCapabilities(camera: true)
            ),
            .grant
        )
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .camera,
                capabilities: PaywallComponent.WebViewCapabilities(camera: false)
            ),
            .deny
        )
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(type: .camera, capabilities: nil),
            .deny
        )
    }

    func testMicrophoneGrantedOnlyWhenMicrophoneTrue() {
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .microphone,
                capabilities: PaywallComponent.WebViewCapabilities(microphone: true)
            ),
            .grant
        )
        // Independent of camera.
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .microphone,
                capabilities: PaywallComponent.WebViewCapabilities(camera: true, microphone: false)
            ),
            .deny
        )
    }

    func testCameraAndMicrophoneRequiresBoth() {
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .cameraAndMicrophone,
                capabilities: PaywallComponent.WebViewCapabilities(camera: true, microphone: true)
            ),
            .grant
        )
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .cameraAndMicrophone,
                capabilities: PaywallComponent.WebViewCapabilities(camera: true, microphone: false)
            ),
            .deny
        )
        XCTAssertEqual(
            WebViewCapabilitiesConfiguration.mediaCaptureDecision(
                type: .cameraAndMicrophone,
                capabilities: PaywallComponent.WebViewCapabilities(camera: false, microphone: true)
            ),
            .deny
        )
    }

    // MARK: - Geolocation bridge JS

    func testGeolocationBridgeScriptOverridesNavigatorGeolocation() {
        let source = PaywallWebViewScripts.geolocationBridgeJavaScriptSource
        XCTAssertTrue(source.contains("navigator.geolocation"))
        XCTAssertTrue(source.contains("getCurrentPosition"))
        XCTAssertTrue(source.contains("window.__rcDeliverGeolocation"))
        XCTAssertTrue(source.contains("window.__rcGeolocationError"))
        XCTAssertTrue(source.contains("rcGeolocation"))
    }

    func testGeolocationBridgeWatchPositionIsANoOpStub() {
        let source = PaywallWebViewScripts.geolocationBridgeJavaScriptSource
        // watchPosition is only a stub returning -1, never wired to the native handler.
        XCTAssertTrue(source.contains("watchPosition: function() { return -1; }"))
    }

    // MARK: - Helpers

    private static func parseRules(_ json: String) throws -> [[String: Any]] {
        let object = try JSONSerialization.jsonObject(with: Data(json.utf8))
        return try XCTUnwrap(object as? [[String: Any]])
    }

}

#endif
