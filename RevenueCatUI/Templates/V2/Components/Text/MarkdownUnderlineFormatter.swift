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
        let tags = Self.underlineTags(in: result)
        let tagPairs = Self.matchedTagPairs(in: tags)

        for pair in tagPairs {
            let contentRange = pair.opening.range.upperBound..<pair.closing.range.lowerBound
            var content = result[contentRange]
            content.underlineStyle = .single
            result[contentRange] = content
        }

        // Match Android by stripping recognized inline HTML tags even when they are unmatched.
        // Process in reverse order so earlier tag offsets remain valid as tags are removed.
        for tag in tags.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            result.replaceSubrange(tag.range, with: AttributedString())
        }

        return result
    }

    private static func underlineTags(in attributedString: AttributedString) -> [Tag] {
        var tags: [Tag] = []

        for run in attributedString.runs
        where run.inlinePresentationIntent?.contains(.inlineHTML) == true {
            let runText = String(attributedString[run.range].characters)
            var index = runText.startIndex

            while index < runText.endIndex {
                let remainingText = runText[index...]
                let kind: TagKind?

                if remainingText.hasPrefix(Self.openingTag) {
                    kind = .opening
                } else if remainingText.hasPrefix(Self.closingTag) {
                    kind = .closing
                } else {
                    kind = nil
                }

                guard let kind else {
                    index = runText.index(after: index)
                    continue
                }

                let tagLength = kind == .opening ? Self.openingTag.count : Self.closingTag.count
                let upperBound = runText.index(index, offsetBy: tagLength)
                let lowerOffset = runText.distance(from: runText.startIndex, to: index)
                let upperOffset = runText.distance(from: runText.startIndex, to: upperBound)
                let lowerBound = attributedString.index(run.range.lowerBound, offsetByCharacters: lowerOffset)
                let attributedUpperBound = attributedString.index(
                    run.range.lowerBound,
                    offsetByCharacters: upperOffset
                )

                tags.append(Tag(kind: kind, range: lowerBound..<attributedUpperBound))
                index = upperBound
            }
        }

        return tags
    }

    private static func matchedTagPairs(in tags: [Tag]) -> [TagPair] {
        var pairs: [TagPair] = []
        var unmatchedOpeningTags: [Tag] = []

        for tag in tags {
            switch tag.kind {
            case .opening:
                unmatchedOpeningTags.append(tag)
            case .closing:
                if let openingTag = unmatchedOpeningTags.popLast() {
                    pairs.append(TagPair(opening: openingTag, closing: tag))
                }
            }
        }

        return pairs
    }

    private struct Tag {
        let kind: TagKind
        let range: Range<AttributedString.Index>
    }

    private enum TagKind {
        case opening
        case closing
    }

    private struct TagPair {
        let opening: Tag
        let closing: Tag
    }

    private static let openingTag = "<u>"
    private static let closingTag = "</u>"

}

#endif
