//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileImageLoaderTests.swift
//
//  Created by RevenueCat on 1/19/26.
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@MainActor
final class FileImageLoaderTests: TestCase {

    func testUpdateURLLoadsNewCachedImage() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("API only available on iOS 16")
        }

        let fileRepository = self.makeFileRepository()
        let url1 = Self.makeLocalURL(filename: "test-image-1.png")
        let url2 = Self.makeLocalURL(filename: "test-image-2.png")

        let data1 = try Self.makeImageData(variant: .red)
        let data2 = try Self.makeImageData(variant: .blue)

        let cachedURL1 = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url1, withChecksum: nil))
        let cachedURL2 = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url2, withChecksum: nil))

        try Self.writeImageData(data1, to: cachedURL1)
        try Self.writeImageData(data2, to: cachedURL2)

        let loader = FileImageLoader(fileRepository: fileRepository, url: url1)
        let firstImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        loader.updateURL(url2)
        let updatedImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        expect(firstImageData).toNot(equal(updatedImageData))
    }

    func testUpdateURLWithSameValueDoesNotResetResult() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("API only available on iOS 16")
        }

        let fileRepository = self.makeFileRepository()
        let url = Self.makeLocalURL(filename: "test-image-3.png")

        let data = try Self.makeImageData(variant: .green)
        let cachedURL = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url, withChecksum: nil))
        try Self.writeImageData(data, to: cachedURL)

        let loader = FileImageLoader(fileRepository: fileRepository, url: url)
        let originalImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        loader.updateURL(url)
        let updatedImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        expect(originalImageData) == updatedImageData
    }

    func testUpdateURLToNilClearsResult() throws {
        let fileRepository = self.makeFileRepository()
        let url = Self.makeLocalURL(filename: "test-image-4.png")

        let data = try Self.makeImageData(variant: .red)
        let cachedURL = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url, withChecksum: nil))
        try Self.writeImageData(data, to: cachedURL)

        let loader = FileImageLoader(fileRepository: fileRepository, url: url)
        expect(loader.result).toNot(beNil())
        expect(loader.url) == url

        loader.updateURL(nil)

        expect(loader.result).to(beNil())
        expect(loader.url).to(beNil())
    }

    func testUpdateURLToNonCachedURLClearsResult() throws {
        let fileRepository = self.makeFileRepository()
        let cachedURL = Self.makeLocalURL(filename: "test-image-7.png")
        let nonCachedURL = Self.makeLocalURL(filename: "test-image-non-cached.png")

        let data = try Self.makeImageData(variant: .green)
        let cachedFileURL = try XCTUnwrap(
            fileRepository.generateLocalFilesystemURL(forRemoteURL: cachedURL, withChecksum: nil)
        )
        try Self.writeImageData(data, to: cachedFileURL)

        let loader = FileImageLoader(fileRepository: fileRepository, url: cachedURL)
        expect(loader.result).toNot(beNil())
        expect(loader.wasLoadedFromCache) == true

        loader.updateURL(nonCachedURL)

        expect(loader.result).to(beNil())
        expect(loader.wasLoadedFromCache) == false
    }

    func testSequentialURLUpdatesLoadCorrectImages() throws {
        guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
            throw XCTSkip("API only available on iOS 16")
        }

        let fileRepository = self.makeFileRepository()
        let url1 = Self.makeLocalURL(filename: "test-seq-1.png")
        let url2 = Self.makeLocalURL(filename: "test-seq-2.png")
        let url3 = Self.makeLocalURL(filename: "test-seq-3.png")

        let data1 = try Self.makeImageData(variant: .red)
        let data2 = try Self.makeImageData(variant: .blue)
        let data3 = try Self.makeImageData(variant: .green)

        let cachedURL1 = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url1, withChecksum: nil))
        let cachedURL2 = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url2, withChecksum: nil))
        let cachedURL3 = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url3, withChecksum: nil))

        try Self.writeImageData(data1, to: cachedURL1)
        try Self.writeImageData(data2, to: cachedURL2)
        try Self.writeImageData(data3, to: cachedURL3)

        let loader = FileImageLoader(fileRepository: fileRepository, url: url1)
        let firstImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        // Simulate rapid package selection changes
        loader.updateURL(url2)
        let secondImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        loader.updateURL(url3)
        let thirdImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        // Return to original
        loader.updateURL(url1)
        let backToFirstImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        // Verify all images are different from each other
        expect(firstImageData).toNot(equal(secondImageData))
        expect(secondImageData).toNot(equal(thirdImageData))
        expect(firstImageData).toNot(equal(thirdImageData))

        // Verify returning to url1 gives the same image as initially
        expect(backToFirstImageData) == firstImageData
    }

    // MARK: - Helpers

    private func makeFileRepository() -> FileRepository {
        return FileRepository(
            networkService: URLSession.shared,
            fileManager: FileManager.default,
            basePath: "FileImageLoaderTests-\(UUID().uuidString)"
        )
    }

    private static func writeImageData(_ data: Data, to url: URL) throws {
        let directoryURL = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private static func makeLocalURL(filename: String) -> URL {
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    // We need valid image bytes because FileImageLoader uses URL.asImageAndSize,
    // which relies on platform decoders (UIImage/NSImage). Dummy bytes would fail to decode.
    // Use tiny pre-encoded PNGs to keep the test platform-agnostic (watchOS has no UIGraphicsImageRenderer).
    private static func makeImageData(variant: TestImageVariant) throws -> Data {
        let base64 = variant.base64PNG
        return try XCTUnwrap(Data(base64Encoded: base64))
    }

}

private enum TestImageVariant: String {
    case red
    case blue
    case green
    var base64PNG: String {
        switch self {
        case .red:
            return "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAD0lEQVR4nGP8z8DA" +
                "wMDAAAAKAgEBrGv0XwAAAABJRU5ErkJggg=="
        case .blue:
            return "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAD0lEQVR4nGNgYPjP" +
                "wMDAAAAKAgEBrGv0XwAAAABJRU5ErkJggg=="
        case .green:
            return "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAD0lEQVR4nGNg+M/A" +
                "wMDAAAAKAgEBrGv0XwAAAABJRU5ErkJggg=="
        }
    }
}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension Image {

    @MainActor
    func platformPNGData() -> Data? {
        guard let image = ImageRenderer(content: self).platformImage else {
            return nil
        }

        return image.pngData()
    }

}
