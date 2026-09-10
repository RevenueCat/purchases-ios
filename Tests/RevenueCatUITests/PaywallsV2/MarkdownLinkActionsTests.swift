//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MarkdownLinkActionsTests.swift

@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

/// Pins down how many actions a paragraph produces. Foundation decides where the runs fall, and
/// a link split across two of them would announce twice with half a title each.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
final class MarkdownLinkActionsTests: TestCase {

    func testLinkWithEmphasisIsOneAction() throws {
        let links = try self.links(in: "Read the [**terms** of service](https://example.com/terms).")

        XCTAssertEqual(links.map(\.title), ["terms of service"])
        XCTAssertEqual(links.map(\.url), [URL(string: "https://example.com/terms")!])
    }

    func testTwoLinksAreTwoActions() throws {
        let links = try self.links(
            in: "See the [terms](https://example.com/terms) and the [policy](https://example.com/policy)."
        )

        XCTAssertEqual(links.map(\.title), ["terms", "policy"])
    }

    /// Two separate links can point at the same place, and each still needs its own action.
    func testRepeatedURLStaysTwoActions() throws {
        let links = try self.links(
            in: "[Read this](https://example.com/terms) or [read it later](https://example.com/terms)."
        )

        XCTAssertEqual(links.map(\.title), ["Read this", "read it later"])
    }

    func testTextWithoutLinksHasNoActions() throws {
        XCTAssertTrue(try self.links(in: "This paragraph has no links at all.").isEmpty)
    }

    // MARK: -

    /// Goes through the view's own `markdownText`, so the runs are split the way they are on screen:
    /// applying the font and the underline formatter re-splits them beyond what markdown alone does.
    private func links(in text: String) throws -> [MarkdownLink] {
        let view = NonLocalizedMarkdownText(text: text, font: .body, fontWeight: .regular)
        let attributed = try XCTUnwrap(view.markdownText)

        return NonLocalizedMarkdownText.markdownLinks(in: attributed)
    }

}

#endif
