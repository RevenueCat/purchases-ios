//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLUtilitiesTests.swift
//
//  Created by Asier G. Morato on 14/9/26.

import Nimble
@testable import RevenueCatUI
import XCTest

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class URLUtilitiesTests: TestCase {

    func testMailURLCarriesRecipientSubjectAndBody() throws {
        let url = try XCTUnwrap(URLUtilities.createMailURLIfPossible(email: "support@revenuecat.com",
                                                                     subject: "Help",
                                                                     body: "Line one"))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        expect(components.scheme) == "mailto"
        expect(components.path) == "support@revenuecat.com"
        expect(components.queryItems).to(contain(URLQueryItem(name: "subject", value: "Help")))
        expect(components.queryItems).to(contain(URLQueryItem(name: "body", value: "Line one")))
    }

    func testMailURLLeavesOutEmptySubjectAndBody() throws {
        let url = try XCTUnwrap(URLUtilities.createMailURLIfPossible(email: "support@revenuecat.com",
                                                                     subject: "",
                                                                     body: ""))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        expect(components.queryItems ?? []).to(beEmpty())
    }

    func testMailURLIsNilWithoutAnEmail() {
        expect(URLUtilities.createMailURLIfPossible(email: "", subject: "Help", body: "Body")).to(beNil())
    }

    #if os(macOS)
    // `canOpenURL` asks Launch Services whether an app handles the URL, which opens nothing, so
    // unlike `openURLIfNotAppExtension` it can run in a test process.
    func testCanOpenAWebURLOnMacOS() throws {
        let url = try XCTUnwrap(URL(string: "https://www.revenuecat.com"))

        expect(URLUtilities.canOpenURL(url)) == true
    }

    func testCannotOpenAURLNoAppHandlesOnMacOS() throws {
        let url = try XCTUnwrap(URL(string: "rc-no-app-handles-this-\(UUID().uuidString.lowercased())://x"))

        expect(URLUtilities.canOpenURL(url)) == false
    }
    #endif

}

#endif
