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

        let data1 = try Self.makeSolidImageData(color: .red)
        let data2 = try Self.makeSolidImageData(color: .blue)

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

        let data = try Self.makeSolidImageData(color: .green)
        let cachedURL = try XCTUnwrap(fileRepository.generateLocalFilesystemURL(forRemoteURL: url, withChecksum: nil))
        try Self.writeImageData(data, to: cachedURL)

        let loader = FileImageLoader(fileRepository: fileRepository, url: url)
        let originalImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        loader.updateURL(url)
        let updatedImageData = try XCTUnwrap(loader.result?.image.platformPNGData())

        expect(originalImageData) == updatedImageData
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
    private static func makeSolidImageData(color: PlatformColor) throws -> Data {
        #if os(macOS)
        let image = NSImage(size: CGSize(width: 2, height: 2))
        image.lockFocus()
        color.setFill()
        NSBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2)).fill()
        image.unlockFocus()

        let tiffData = try XCTUnwrap(image.tiffRepresentation)
        let rep = try XCTUnwrap(NSBitmapImageRep(data: tiffData))
        return try XCTUnwrap(rep.representation(using: .png, properties: [:]))
        #else
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { _ in
            color.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 2, height: 2)).fill()
        }
        return try XCTUnwrap(image.pngData())
        #endif
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
