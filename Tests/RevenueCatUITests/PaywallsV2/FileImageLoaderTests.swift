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

    func testConcurrentDecodedImageLoadsDoNotDeadlockSwiftConcurrency() async throws {
        let imageCount = max(ProcessInfo.processInfo.activeProcessorCount * 8, 128)
        let data = try Self.makeImageData(variant: .red)
        let urls = try (0..<imageCount).map { index -> URL in
            let url = Self.makeLocalURL(filename: "test-concurrent-\(UUID().uuidString)-\(index).png")
            try Self.writeImageData(data, to: url)
            return url
        }

        let completion = self.expectation(description: "Concurrent decoded image loads complete")
        let task = Task {
            // Simulates first paywall presentation loading many images from Swift concurrency.
            let allImagesLoaded = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
                for url in urls {
                    group.addTask {
                        return url.asImageAndSize != nil
                    }
                }

                var allImagesLoaded = true
                for await didLoadImage in group {
                    allImagesLoaded = allImagesLoaded && didLoadImage
                }

                return allImagesLoaded
            }

            expect(allImagesLoaded) == true
            completion.fulfill()
        }
        defer { task.cancel() }

        await self.fulfillment(of: [completion], timeout: 5)
    }

    #if os(iOS)
    // A tab switch reuses the image view at the same position with a new URL.
    // No render for the new URL may show the previous URL's image.
    func testRemoteImageNeverRendersPreviousURLsImageAfterURLChange() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("API only available on iOS 16")
        }

        let urlA = try XCTUnwrap(URL(string: "https://assets.example.com/\(UUID().uuidString)-a.png"))
        let urlB = try XCTUnwrap(URL(string: "https://assets.example.com/\(UUID().uuidString)-b.png"))
        let dataA = try Self.makeImageData(variant: .red)
        let dataB = try Self.makeImageData(variant: .blue)
        try Self.writeImageData(dataA, to: try XCTUnwrap(
            FileRepository.shared.generateLocalFilesystemURL(forRemoteURL: urlA, withChecksum: nil)
        ))
        try Self.writeImageData(dataB, to: try XCTUnwrap(
            FileRepository.shared.generateLocalFilesystemURL(forRemoteURL: urlB, withChecksum: nil)
        ))

        let model = RemoteImageURLModel(url: urlA)
        let recorder = RemoteImageRenderRecorder()
        let controller = UIHostingController(rootView: RemoteImageURLHost(model: model, recorder: recorder))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }

        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        model.url = urlB
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let rendersForB = recorder.renders.filter { $0.url == urlB }
        expect(rendersForB).toNot(beEmpty())
        // A is red, B is blue.
        expect(rendersForB.map { $0.image.isMostlyRed() }).toNot(contain(true))
    }
    #endif

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

#if os(iOS)
private final class RemoteImageURLModel: ObservableObject {
    @Published var url: URL
    init(url: URL) { self.url = url }
}

private final class RemoteImageRenderRecorder {
    var renders: [(url: URL, image: Image)] = []

    func record(_ image: Image, for url: URL) -> Image {
        self.renders.append((url: url, image: image))
        return image
    }
}

@available(iOS 15.0, *)
private struct RemoteImageURLHost: View {
    @ObservedObject var model: RemoteImageURLModel
    let recorder: RemoteImageRenderRecorder

    var body: some View {
        let url = self.model.url
        RemoteImage(url: url) { image, _ in
            self.recorder.record(image, for: url).resizable()
        }
    }
}
#endif

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private extension Image {

    #if os(iOS)
    @MainActor
    func isMostlyRed() -> Bool {
        guard let cgImage = ImageRenderer(content: self.resizable().frame(width: 2, height: 2)).cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return false
        }
        let isBGR = cgImage.bitmapInfo.contains(.byteOrder32Little)
        let red = isBGR ? bytes[2] : bytes[0]
        let blue = isBGR ? bytes[0] : bytes[2]
        return red > blue
    }
    #endif

    @MainActor
    func platformPNGData() -> Data? {
        guard let image = ImageRenderer(content: self).platformImage else {
            return nil
        }

        return image.pngData()
    }

}
