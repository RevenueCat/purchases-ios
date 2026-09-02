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

        guard let regex = NSRegularExpression.underlineHTML else {
            return result
        }

        let nsRange = NSRange(plainString.startIndex..., in: plainString)
        let matches = regex.matches(in: plainString, options: [], range: nsRange)

        func attributedRange(for nsRange: NSRange) -> Range<AttributedString.Index>? {
            guard let range = Range(nsRange, in: plainString) else {
                return nil
            }

            let lowerOffset = plainString.distance(from: plainString.startIndex, to: range.lowerBound)
            let upperOffset = plainString.distance(from: plainString.startIndex, to: range.upperBound)
            let lowerBound = result.index(result.startIndex, offsetByCharacters: lowerOffset)
            let upperBound = result.index(result.startIndex, offsetByCharacters: upperOffset)

            return lowerBound..<upperBound
        }

        // Process in reverse order so earlier match offsets remain valid as tags are removed.
        for match in matches.reversed() {
            guard let fullRange = attributedRange(for: match.range),
                  let contentRange = attributedRange(for: match.range(at: 1)) else {
                continue
            }

            var content = AttributedString(result[contentRange])
            if !content.characters.isEmpty {
                content.underlineStyle = .single
            }

            result.replaceSubrange(fullRange, with: content)
        }

        return result
    }

}

private extension NSRegularExpression {

    static let underlineHTML = try? NSRegularExpression(
        pattern: "<u>(.*?)</u>",
        options: [.dotMatchesLineSeparators]
    )

}

#endif
