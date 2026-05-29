//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InMemoryHTMLFileRepository.swift
//
//  Created by RevenueCat.
//

import Foundation

// swiftlint:disable file_length

/// An in-memory HTML file repository that rewrites cacheable assets to local URLs.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
@_spi(Internal) public final class InMemoryHTMLFileRepository: InMemoryHTMLFileRepositoryType, @unchecked Sendable {

    /// A shared in-memory HTML file repository.
    @_spi(Internal) public static let shared = InMemoryHTMLFileRepository()

    private let networkService: SimpleNetworkServiceType
    private let htmlStore = KeyedDeferredValueStore<InputURL, OutputURL>()
    private let assetStore = KeyedDeferredValueStore<InputURL, OutputURL>()

    init(networkService: SimpleNetworkServiceType = URLSession.shared) {
        self.networkService = networkService
    }

    /// Create an in-memory HTML file repository.
    @_spi(Internal) public convenience init() {
        self.init(networkService: URLSession.shared)
    }

    /// Create a URL session configuration that can load cached `purchaseshtml` URLs.
    @_spi(Internal) public static func makeURLSessionConfiguration(
        from configuration: URLSessionConfiguration = .ephemeral
    ) -> URLSessionConfiguration {
        let result = configuration.copy() as? URLSessionConfiguration ?? .ephemeral
        let existingProtocolClasses = result.protocolClasses ?? []
        result.protocolClasses = [InMemoryHTMLURLProtocol.self] + existingProtocolClasses

        return result
    }

    /// Create and/or get the in-memory cached HTML URL.
    @_spi(Internal) public func generateOrGetCachedFileURL(for url: InputURL) async throws -> OutputURL {
        guard url.isHTTPSWithHost else {
            throw Error.invalidURLScheme
        }

        if let cachedURL = await InMemoryHTMLURLProtocol.cachedURL(for: url) {
            return cachedURL
        }

        let cachedURL = try await self.htmlStore.getOrPut(
            Task { [weak self] in
                guard let self else {
                    throw Error.failedToCacheHTML
                }

                return try await self.cacheHTML(at: url)
            },
            forKey: url
        ).value

        return cachedURL
    }

    /// Get the in-memory cached HTML URL if it exists.
    @_spi(Internal) public func getCachedFileURL(for url: InputURL) -> OutputURL? {
        return InMemoryHTMLURLProtocol.cachedURL(for: url)
    }

    private func cacheHTML(at url: URL) async throws -> URL {
        let data = try await self.data(from: url)
        let html = String(bytes: [UInt8](data), encoding: .utf8) ?? ""
        let rewrittenHTML = await HTMLAssetRewriter(baseURL: url) { [weak self] assetURL, kind in
            guard let self else { return nil }
            return try? await self.cacheAsset(at: assetURL, kind: kind)
        }.rewrite(html)

        return InMemoryHTMLURLProtocol.store(
            data: rewrittenHTML.asData,
            mimeType: "text/html",
            for: url
        )
    }

    private func cacheAsset(at url: URL, kind: AssetKind) async throws -> URL {
        guard url.isHTTPSWithHost else {
            throw Error.invalidURLScheme
        }

        if let cachedURL = InMemoryHTMLURLProtocol.cachedURL(for: url) {
            return cachedURL
        }

        return try await self.assetStore.getOrPut(
            Task { [weak self] in
                guard let self else {
                    throw Error.failedToCacheAsset
                }

                let data = try await self.data(from: url)
                let cachedData: Data
                if kind == .stylesheet {
                    let css = String(bytes: [UInt8](data), encoding: .utf8) ?? ""
                    let rewrittenCSS = await CSSAssetRewriter(baseURL: url) { [weak self] assetURL, kind in
                        guard let self else { return nil }
                        return try? await self.cacheAsset(at: assetURL, kind: kind)
                    }.rewrite(css)
                    cachedData = rewrittenCSS.asData
                } else {
                    cachedData = data
                }

                let cachedURL = InMemoryHTMLURLProtocol.store(
                    data: cachedData,
                    mimeType: kind.mimeType(for: url),
                    for: url
                )

                return cachedURL
            },
            forKey: url
        ).value
    }

    private func data(from url: URL) async throws -> Data {
        do {
            let bytes = try await self.networkService.bytes(from: url)
            var data = Data()

            for try await byte in bytes {
                data.append(byte)
            }

            return data
        } catch {
            throw Error.failedToFetchURL(url.absoluteString)
        }
    }

}

/// An in-memory HTML file repository.
@_spi(Internal) public protocol InMemoryHTMLFileRepositoryType: Sendable {

    /// Create and/or get the in-memory cached HTML URL.
    func generateOrGetCachedFileURL(for url: InputURL) async throws -> OutputURL

    /// Get the in-memory cached HTML URL if it exists.
    func getCachedFileURL(for url: InputURL) -> OutputURL?

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
extension InMemoryHTMLFileRepository {

    /// In-memory HTML file repository error cases.
    @_spi(Internal) public enum Error: Swift.Error {
        /// Used when a URL does not use HTTPS.
        case invalidURLScheme

        /// Used when the repository cannot cache the HTML document.
        case failedToCacheHTML

        /// Used when the repository cannot cache an asset.
        case failedToCacheAsset

        /// Used when fetching a URL fails.
        case failedToFetchURL(String)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private struct HTMLAssetRewriter {

    typealias CacheAsset = @Sendable (URL, AssetKind) async -> URL?

    let baseURL: URL
    let cacheAsset: CacheAsset

    func rewrite(_ html: String) async -> String {
        var replacements: [StringReplacement] = []

        replacements += await self.replacements(in: html, tag: "link", attribute: "href") { tag in
            guard let rel = tag.attributeValue(named: "rel") else { return nil }
            return rel.lowercased().split(whereSeparator: \.isWhitespace).contains { $0 == "stylesheet" }
                ? .stylesheet
                : nil
        }

        replacements += await self.replacements(in: html, tag: "script", attribute: "src") { _ in .script }
        replacements += await self.replacements(in: html, tag: "img", attribute: "src") { _ in .image }
        replacements += await self.srcsetReplacements(in: html, tag: "img")
        replacements += await self.srcsetReplacements(in: html, tag: "source")
        replacements += await self.quotedJSONReplacements(in: html)

        return html.applying(replacements)
    }

    private func replacements(
        in html: String,
        tag: String,
        attribute: String,
        kind: (String) -> AssetKind?
    ) async -> [StringReplacement] {
        let tagRanges = html.ranges(matching: "(?is)<\(tag)\\b[^>]*>")
        var replacements: [StringReplacement] = []

        for tagRange in tagRanges {
            let tagText = String(html[tagRange])
            guard let assetKind = kind(tagText),
                  let attributeValue = tagText.attribute(named: attribute),
                  let assetURL = attributeValue.value.resolvedResourceURL(relativeTo: self.baseURL),
                  let valueRange = html.offsetRange(attributeValue.valueRange, in: tagText, at: tagRange),
                  let attributeRange = html.offsetRange(attributeValue.range, in: tagText, at: tagRange) else {
                continue
            }

            guard assetURL.isHTTPSWithHost else {
                let rangeToStrip = assetKind.removesWholeHTMLTagWhenBlocked ? tagRange : attributeRange
                replacements.append(.init(range: rangeToStrip, replacement: ""))
                continue
            }

            guard let cachedURL = await self.cacheAsset(assetURL, assetKind) else {
                continue
            }

            replacements.append(.init(range: valueRange, replacement: cachedURL.absoluteString))
        }

        return replacements
    }

    private func srcsetReplacements(in html: String, tag: String) async -> [StringReplacement] {
        let tagRanges = html.ranges(matching: "(?is)<\(tag)\\b[^>]*>")
        var replacements: [StringReplacement] = []

        for tagRange in tagRanges {
            let tagText = String(html[tagRange])
            guard let attributeValue = tagText.attributeValueAndRange(named: "srcset"),
                  let valueRange = html.offsetRange(attributeValue.range, in: tagText, at: tagRange) else {
                continue
            }

            let rewritten = await self.rewriteSrcset(attributeValue.value)
            if rewritten != attributeValue.value {
                replacements.append(.init(range: valueRange, replacement: rewritten))
            }
        }

        return replacements
    }

    private func rewriteSrcset(_ srcset: String) async -> String {
        var candidates: [String] = []

        for rawCandidate in srcset.split(separator: ",", omittingEmptySubsequences: false) {
            let candidate = String(rawCandidate)
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.split(maxSplits: 1, whereSeparator: \.isWhitespace)

            guard let firstPart = parts.first,
                  let assetURL = String(firstPart).resolvedResourceURL(relativeTo: self.baseURL) else {
                candidates.append(candidate)
                continue
            }

            guard assetURL.isHTTPSWithHost else {
                continue
            }

            guard let cachedURL = await self.cacheAsset(assetURL, .image) else {
                candidates.append(candidate)
                continue
            }

            let descriptor = parts.dropFirst().first.map { " \($0)" } ?? ""
            candidates.append(candidate.replacingOccurrences(
                of: String(firstPart) + descriptor,
                with: cachedURL.absoluteString + descriptor
            ))
        }

        return candidates.joined(separator: ",")
    }

    private func quotedJSONReplacements(in html: String) async -> [StringReplacement] {
        let matches = html.matches(
            pattern: #"(?is)(?:"([^"]+\.json(?:[?#][^"]*)?)"|'([^']+\.json(?:[?#][^']*)?)')"#
        )

        var replacements: [StringReplacement] = []
        for match in matches {
            guard let value = match.firstCapture(in: html),
                  let assetURL = value.value.resolvedResourceURL(relativeTo: self.baseURL) else {
                continue
            }

            guard assetURL.isHTTPSWithHost else {
                replacements.append(.init(range: value.range, replacement: ""))
                continue
            }

            guard let cachedURL = await self.cacheAsset(assetURL, .asset) else {
                continue
            }

            replacements.append(.init(range: value.range, replacement: cachedURL.absoluteString))
        }

        return replacements
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private struct CSSAssetRewriter {

    typealias CacheAsset = @Sendable (URL, AssetKind) async -> URL?

    let baseURL: URL
    let cacheAsset: CacheAsset

    func rewrite(_ css: String) async -> String {
        var replacements: [StringReplacement] = []

        replacements += await self.importURLReplacements(in: css)
        replacements += await self.cssURLReplacements(in: css)
        replacements += await self.importStringReplacements(in: css)

        return css.applying(replacements)
    }

    private func cssURLReplacements(in css: String) async -> [StringReplacement] {
        let matches = css.matches(
            pattern: #"(?is)\burl\(\s*(?:"([^"]*)"|'([^']*)'|([^'")\s]+))\s*\)"#
        )

        var replacements: [StringReplacement] = []
        for match in matches {
            guard !css.isImportURL(match),
                  let value = match.firstCapture(in: css),
                  let assetURL = value.value.resolvedResourceURL(relativeTo: self.baseURL) else {
                continue
            }

            guard assetURL.isHTTPSWithHost else {
                replacements.append(.init(range: value.range, replacement: Self.blockedURLString))
                continue
            }

            guard let cachedURL = await self.cacheAsset(assetURL, .asset) else {
                continue
            }

            replacements.append(.init(range: value.range, replacement: cachedURL.absoluteString))
        }

        return replacements
    }

    private func importURLReplacements(in css: String) async -> [StringReplacement] {
        let matches = css.matches(
            pattern: #"(?is)@import\s+url\(\s*(?:"([^"]*)"|'([^']*)'|([^'")\s]+))\s*\)"#
        )

        var replacements: [StringReplacement] = []
        for match in matches {
            guard let value = match.firstCapture(in: css),
                  let matchRange = match.ranges.first ?? nil,
                  let assetURL = value.value.resolvedResourceURL(relativeTo: self.baseURL) else {
                continue
            }

            guard assetURL.isHTTPSWithHost else {
                replacements.append(.init(range: matchRange, replacement: ""))
                continue
            }

            guard let cachedURL = await self.cacheAsset(assetURL, .stylesheet) else {
                continue
            }

            replacements.append(.init(range: value.range, replacement: cachedURL.absoluteString))
        }

        return replacements
    }

    private func importStringReplacements(in css: String) async -> [StringReplacement] {
        let matches = css.matches(
            pattern: #"(?is)@import\s+(?:"([^"]*)"|'([^']*)')"#
        )

        var replacements: [StringReplacement] = []
        for match in matches {
            guard let value = match.firstCapture(in: css),
                  let matchRange = match.ranges.first ?? nil,
                  let assetURL = value.value.resolvedResourceURL(relativeTo: self.baseURL) else {
                continue
            }

            guard assetURL.isHTTPSWithHost else {
                replacements.append(.init(range: matchRange, replacement: ""))
                continue
            }

            guard let cachedURL = await self.cacheAsset(assetURL, .stylesheet) else {
                continue
            }

            replacements.append(.init(range: value.range, replacement: cachedURL.absoluteString))
        }

        return replacements
    }

    private static let blockedURLString = "data:,"

}

private enum AssetKind: Sendable {
    case stylesheet
    case script
    case image
    case asset

    var removesWholeHTMLTagWhenBlocked: Bool {
        switch self {
        case .stylesheet, .script:
            return true
        case .image, .asset:
            return false
        }
    }

    func mimeType(for url: URL) -> String? {
        switch self {
        case .stylesheet:
            return "text/css"
        case .script:
            return "application/javascript"
        case .image:
            return Self.imageMimeType(for: url.pathExtension)
        case .asset:
            return Self.mimeType(for: url.pathExtension)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func mimeType(for pathExtension: String) -> String? {
        switch pathExtension.lowercased() {
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "svg": return "image/svg+xml"
        case "json": return "application/json"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "ttf": return "font/ttf"
        case "otf": return "font/otf"
        default: return nil
        }
    }

    private static func imageMimeType(for pathExtension: String) -> String? {
        return self.mimeType(for: pathExtension) ?? "image/*"
    }
}

private struct StringReplacement {
    let range: Range<String.Index>
    let replacement: String
}

private struct RegexMatch {
    let ranges: [Range<String.Index>?]

    func firstCapture(in string: String) -> (value: String, range: Range<String.Index>)? {
        for range in self.ranges.dropFirst() {
            if let range {
                return (String(string[range]), range)
            }
        }

        return nil
    }
}

private struct HTMLAttribute {
    let value: String
    let range: Range<String.Index>
    let valueRange: Range<String.Index>
}

private extension String {

    func applying(_ replacements: [StringReplacement]) -> String {
        return replacements
            .sorted { $0.range.lowerBound > $1.range.lowerBound }
            .reduce(into: self) { result, replacement in
                result.replaceSubrange(replacement.range, with: replacement.replacement)
            }
    }

    func ranges(matching pattern: String) -> [Range<String.Index>] {
        return self.matches(pattern: pattern).compactMap { $0.ranges.first ?? nil }
    }

    func matches(pattern: String) -> [RegexMatch] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsRange = NSRange(self.startIndex..<self.endIndex, in: self)
        return regex.matches(in: self, range: nsRange).map { match in
            let ranges = (0..<match.numberOfRanges).map { index in
                Range(match.range(at: index), in: self)
            }

            return RegexMatch(ranges: ranges)
        }
    }

    func attributeValue(named attribute: String) -> String? {
        return self.attribute(named: attribute)?.value
    }

    func attributeValueAndRange(named attribute: String) -> (value: String, range: Range<String.Index>)? {
        return self.attribute(named: attribute).map { ($0.value, $0.valueRange) }
    }

    func attribute(named attribute: String) -> HTMLAttribute? {
        let escapedAttribute = NSRegularExpression.escapedPattern(for: attribute)
        let pattern = #"(?is)(?:^|\s)"# + escapedAttribute + #"\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))"#

        guard let match = self.matches(pattern: pattern).first,
              let range = match.ranges.first ?? nil,
              let value = match.firstCapture(in: self) else {
            return nil
        }

        return HTMLAttribute(value: value.value, range: range, valueRange: value.range)
    }

    func resolvedResourceURL(relativeTo baseURL: URL) -> URL? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.hasPrefix("#"),
              let url = URL(string: trimmed, relativeTo: baseURL)?.absoluteURL else {
            return nil
        }

        return url
    }

    func offsetRange(
        _ range: Range<String.Index>,
        in substring: String,
        at substringRange: Range<String.Index>
    ) -> Range<String.Index>? {
        let lowerDistance = substring.distance(from: substring.startIndex, to: range.lowerBound)
        let upperDistance = substring.distance(from: substring.startIndex, to: range.upperBound)

        guard let lowerBound = self.index(
            substringRange.lowerBound,
            offsetBy: lowerDistance,
            limitedBy: substringRange.upperBound
        ), let upperBound = self.index(
            substringRange.lowerBound,
            offsetBy: upperDistance,
            limitedBy: substringRange.upperBound
        ) else {
            return nil
        }

        return lowerBound..<upperBound
    }

    func isImportURL(_ match: RegexMatch) -> Bool {
        guard let matchRange = match.ranges.first ?? nil else {
            return false
        }

        let prefix = self[..<matchRange.lowerBound]
            .suffix(20)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return prefix.hasSuffix("@import")
    }

}

private extension URL {

    var isHTTPSWithHost: Bool {
        return self.scheme?.lowercased() == "https" && self.host?.isEmpty == false
    }

}
