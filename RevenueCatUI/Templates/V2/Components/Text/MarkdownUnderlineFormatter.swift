//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, watchOS 8.0, *)
enum MarkdownUnderlineFormatter {

    /// Processes `<u>text</u>` syntax and applies underline styling.
    static func apply(to attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        let plainString = String(result.characters)
        let tagPairs = Self.matchedTagPairs(in: plainString)

        func attributedRange(for range: Range<String.Index>) -> Range<AttributedString.Index> {
            let lowerOffset = plainString.distance(from: plainString.startIndex, to: range.lowerBound)
            let upperOffset = plainString.distance(from: plainString.startIndex, to: range.upperBound)
            let lowerBound = result.index(result.startIndex, offsetByCharacters: lowerOffset)
            let upperBound = result.index(result.startIndex, offsetByCharacters: upperOffset)

            return lowerBound..<upperBound
        }

        for pair in tagPairs {
            let contentRange = attributedRange(for: pair.opening.range.upperBound..<pair.closing.range.lowerBound)
            var content = result[contentRange]
            content.underlineStyle = .single
            result[contentRange] = content
        }

        // Process in reverse order so earlier tag offsets remain valid as tags are removed.
        let matchedTags = tagPairs
            .flatMap { [$0.opening, $0.closing] }
            .sorted { $0.range.lowerBound > $1.range.lowerBound }
        for tag in matchedTags {
            result.replaceSubrange(attributedRange(for: tag.range), with: AttributedString())
        }

        return result
    }

    private static func matchedTagPairs(in string: String) -> [TagPair] {
        var pairs: [TagPair] = []
        var unmatchedOpeningTags: [Tag] = []
        var index = string.startIndex

        while index < string.endIndex {
            let remainingText = string[index...]

            if remainingText.hasPrefix(Self.openingTag) {
                let upperBound = string.index(index, offsetBy: Self.openingTag.count)
                let tag = Tag(range: index..<upperBound)
                unmatchedOpeningTags.append(tag)
                index = upperBound
            } else if remainingText.hasPrefix(Self.closingTag) {
                let upperBound = string.index(index, offsetBy: Self.closingTag.count)
                if let openingTag = unmatchedOpeningTags.popLast() {
                    pairs.append(TagPair(opening: openingTag, closing: Tag(range: index..<upperBound)))
                }
                index = upperBound
            } else {
                index = string.index(after: index)
            }
        }

        return pairs
    }

    private struct Tag {
        let range: Range<String.Index>
    }

    private struct TagPair {
        let opening: Tag
        let closing: Tag
    }

    private static let openingTag = "<u>"
    private static let closingTag = "</u>"

}

#endif
