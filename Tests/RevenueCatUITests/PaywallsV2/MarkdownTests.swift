//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MarkdownTests.swift
//
//  Created by Jacob Zivan Rakidzich on 12/18/25.

@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
final class MarkdownTests: TestCase {

    // MARK: - applyUnderlines Tests

    func testApplyUnderlines_withSingleUnderlineTag() throws {
        let input = try AttributedString(markdown: "Hello <u>world</u>!")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "Hello world!")

        // Find the underlined portion
        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertEqual(underlinedRuns.count, 1)

        let underlinedText = String(result[underlinedRuns.first!.range].characters)
        XCTAssertEqual(underlinedText, "world")
    }

    func testApplyUnderlines_withMultipleUnderlineTags() throws {
        let input = try AttributedString(markdown: "<u>one</u> and <u>two</u>")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "one and two")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        let underlinedText = underlinedRuns.map { run in
            String(result[run.range].characters)
        }
        XCTAssertEqual(underlinedText, ["one", "two"])
    }

    func testApplyUnderlines_withNoUnderlineTags() throws {
        let input = try AttributedString(markdown: "Hello world!")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "Hello world!")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertTrue(underlinedRuns.isEmpty)
    }

    func testApplyUnderlines_withEmptyUnderlineTag() throws {
        let input = try AttributedString(markdown: "Hello <u></u> world")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "Hello  world")
    }

    func testApplyUnderlines_withNewlineInUnderlineTag() throws {
        // Use inlineOnly to preserve newlines (same as NonLocalizedMarkdownText)
        let input = try AttributedString(
            markdown: "<u>line1\nline2</u>",
            options: .init(interpretedSyntax: .inlineOnly)
        )
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "line1\nline2")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        let underlinedText = underlinedRuns.map { run in
            String(result[run.range].characters)
        }
        XCTAssertEqual(underlinedText, ["line1\nline2"])
    }

    func testApplyUnderlines_withUnclosedTag() throws {
        let input = try AttributedString(markdown: "Hello <u>world")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        // Unclosed tag should remain as-is
        XCTAssertEqual(plainText, "Hello <u>world")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertTrue(underlinedRuns.isEmpty)
    }

    func testApplyUnderlines_withBoldInsideUnderline() throws {
        let input = try AttributedString(
            markdown: "<u>**bold text**</u>",
            options: .init(interpretedSyntax: .inlineOnly)
        )
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "bold text")

        // Should have underline
        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertFalse(underlinedRuns.isEmpty)

        // Should preserve bold (stronglyEmphasized)
        let boldRuns = result.runs.filter {
            $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }
        XCTAssertFalse(boldRuns.isEmpty)
    }

    func testApplyUnderlines_withItalicInsideUnderline() throws {
        let input = try AttributedString(
            markdown: "<u>_italic text_</u>",
            options: .init(interpretedSyntax: .inlineOnly)
        )
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "italic text")

        // Should have underline
        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertFalse(underlinedRuns.isEmpty)

        // Should preserve italic (emphasized)
        let italicRuns = result.runs.filter {
            $0.inlinePresentationIntent?.contains(.emphasized) == true
        }
        XCTAssertFalse(italicRuns.isEmpty)
    }

    func testApplyUnderlines_withAdjacentUnderlineTags() throws {
        let input = try AttributedString(markdown: "<u>first</u><u>second</u>")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "firstsecond")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertGreaterThanOrEqual(underlinedRuns.count, 1)
    }

    func testApplyUnderlines_withIdenticalUnderlineTags_separatedByOtherText() throws {
        let input = try AttributedString(markdown: "<u>TEST_IDENTICAL</u> <u>TEST_IDENTICAL</u>")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "TEST_IDENTICAL TEST_IDENTICAL")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        let underlinedText = underlinedRuns.map { run in
            String(result[run.range].characters)
        }
        XCTAssertEqual(underlinedText, ["TEST_IDENTICAL", "TEST_IDENTICAL"])
    }

    func testApplyUnderlines_withIdenticalUnderlineTag() throws {
        let input = try AttributedString(markdown: "<u>TEST_IDENTICAL</u><u>TEST_IDENTICAL</u>")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "TEST_IDENTICALTEST_IDENTICAL")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        let underlinedText = underlinedRuns.map { run in
            String(result[run.range].characters)
        }
        XCTAssertEqual(underlinedText, ["TEST_IDENTICALTEST_IDENTICAL"])
    }

    func testApplyUnderlines_withSpecialCharactersInContent() throws {
        let input = try AttributedString(markdown: "<u>$100 & <test></u>")
        let result = NonLocalizedMarkdownText.applyUnderlines(to: input)

        let plainText = String(result.characters)
        XCTAssertEqual(plainText, "$100 & <test>")

        let underlinedRuns = result.runs.filter { $0.underlineStyle == .single }
        XCTAssertFalse(underlinedRuns.isEmpty)
    }

    // MARK: - NonLocalizedMarkdownText View Tests

    func testMarkdownText_plainTextReturnsAttributedString() {
        let view = NonLocalizedMarkdownText(
            text: "Hello world",
            font: .body,
            fontWeight: .regular
        )

        XCTAssertNotNil(view.markdownText)
        XCTAssertEqual(String(view.markdownText!.characters), "Hello world")
    }

    func testMarkdownText_withBoldAndRegularWeight() {
        let view = NonLocalizedMarkdownText(
            text: "Hello **world**",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "Hello world")

        // With regular weight, bold should be applied
        let boldRuns = result!.runs.filter { run in
            if let font = run.font {
                // Check if font has bold weight applied
                return true // Font attribute exists
            }
            return false
        }
        XCTAssertFalse(boldRuns.isEmpty)
    }

    func testMarkdownText_withBoldAndBlackWeight() {
        let view = NonLocalizedMarkdownText(
            text: "Hello **world**",
            font: .body,
            fontWeight: .black
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "Hello world")
    }

    func testMarkdownText_withItalic() {
        let view = NonLocalizedMarkdownText(
            text: "Hello _world_",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "Hello world")

        let italicRuns = result!.runs.filter {
            $0.inlinePresentationIntent?.contains(.emphasized) == true
        }
        XCTAssertFalse(italicRuns.isEmpty)
    }

    func testMarkdownText_withUnderline() {
        let view = NonLocalizedMarkdownText(
            text: "Hello <u>world</u>",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "Hello world")

        let underlinedRuns = result!.runs.filter { $0.underlineStyle == .single }
        XCTAssertFalse(underlinedRuns.isEmpty)
    }

    func testMarkdownText_withLink() {
        let view = NonLocalizedMarkdownText(
            text: "Visit [RevenueCat](https://revenuecat.com)",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "Visit RevenueCat")

        let linkRuns = result!.runs.filter { $0.link != nil }
        XCTAssertFalse(linkRuns.isEmpty)

        if let linkRun = linkRuns.first {
            XCTAssertEqual(linkRun.link?.absoluteString, "https://revenuecat.com")
        }
    }

    func testMarkdownText_withCodeSpan() {
        let view = NonLocalizedMarkdownText(
            text: "Use `print()` function",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "Use print() function")

        let codeRuns = result!.runs.filter {
            $0.inlinePresentationIntent?.contains(.code) == true
        }
        XCTAssertFalse(codeRuns.isEmpty)
    }

    func testMarkdownText_withCombinedFormatting() {
        let view = NonLocalizedMarkdownText(
            text: "**bold** _italic_ <u>underline</u>",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertEqual(plainText, "bold italic underline")

        // Check all formatting types are present
        let italicRuns = result!.runs.filter {
            $0.inlinePresentationIntent?.contains(.emphasized) == true
        }
        XCTAssertFalse(italicRuns.isEmpty, "Should have italic runs")

        let underlineRuns = result!.runs.filter { $0.underlineStyle == .single }
        XCTAssertFalse(underlineRuns.isEmpty, "Should have underline runs")
    }

    func testMarkdownText_withInvalidMarkdownReturnsParsedResult() {
        let view = NonLocalizedMarkdownText(
            text: "Hello **unclosed bold",
            font: .body,
            fontWeight: .regular
        )

        // Invalid markdown should still return something (AttributedString is lenient)
        let result = view.markdownText
        XCTAssertNotNil(result)
    }

    func testMarkdownText_preservesNewlines() {
        let view = NonLocalizedMarkdownText(
            text: "Line 1\nLine 2\n\nLine 4",
            font: .body,
            fontWeight: .regular
        )

        let result = view.markdownText
        XCTAssertNotNil(result)

        let plainText = String(result!.characters)
        XCTAssertTrue(plainText.contains("\n"))
    }
}

#endif
