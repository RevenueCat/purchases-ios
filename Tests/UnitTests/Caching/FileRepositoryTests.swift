//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileRepositoryTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
class FileRepositoryTests: TestCase {
    let someURL = URL(string: "https://somesite.com/someurl.mp4").unsafelyUnwrapped

    func test_ifContentExists_networkServiceIsNotCalled() async throws {
        let sut = await makeSystemUnderTest()
        sut.cache.stubCachedContentExists(with: true)
        let data = try await sut.fileRepository.generateOrGetCachedFileURL(for: someURL, withChecksum: nil)

        XCTAssertNotNil(data)
        XCTAssertEqual(sut.networkService.invocations, [])
    }

    func test_prefetch_invokesNetwork() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".data(using: .utf8).unsafelyUnwrapped

        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))

        await Task(priority: .userInitiated) {
            sut.fileRepository.prefetch(urls: [someURL])
        }.value

        await yield()

        await expect(sut.networkService.invocations.count).toEventually(equal(1))
    }

    func test_whenCacheURLCannotBeAssembled_returnsNil() async throws {
        let sut = await makeSystemUnderTest(cacheDirectoryURL: nil)
        do {
            _ = try await sut.fileRepository.generateOrGetCachedFileURL(for: someURL, withChecksum: nil)
        } catch {
            switch error as? FileRepository.Error {
            case .failedToCreateCacheDirectory: break
            default:
                XCTFail(#function)
            }
        }

        XCTAssertEqual(sut.cache.cachedContentExistsInvocations, [])
    }

    func test_whenNetworkServiceFails_completesWithError() async {
        let sut = await makeSystemUnderTest()

        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .failure(SampleError()))
        do {
            _ = try await sut.fileRepository.generateOrGetCachedFileURL(for: someURL, withChecksum: nil)
            XCTFail(#function)
        } catch {
            switch error as? FileRepository.Error {
            case .failedToFetchFileFromRemoteSource:
                break
            default:
                XCTFail(#function)
            }
        }
    }

    func test_savingData_mapsURLToNewURLType_andReturnsIt() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".data(using: .utf8).unsafelyUnwrapped
        sut.cache.stubCachedContentExists(with: false)
        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        let result = try await sut.fileRepository.generateOrGetCachedFileURL(for: someURL, withChecksum: nil)

        let expectedCachedURL = URL(
            string: "data:sample/RevenueCat/1b548ae1c45e1ffe5de61ce60e03b277someurl.mp4"
        ).unsafelyUnwrapped

        XCTAssertEqual(sut.networkService.invocations, [someURL])
        XCTAssertEqual(sut.cache.saveDataInvocations, [.init(data: data, url: expectedCachedURL)])
        XCTAssertEqual(result, expectedCachedURL)
        XCTAssertNotEqual(someURL, expectedCachedURL)
    }

    func test_savingData_mapsURLToNewURLType_withChecksum_andReturnsIt() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".data(using: .utf8).unsafelyUnwrapped
        let checksum = Checksum(algorithm: .md5, value: "mock-checksum-value-")
        sut.cache.stubCachedContentExists(with: false)
        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        let result = try await sut.fileRepository.generateOrGetCachedFileURL(
            for: someURL,
            withChecksum: checksum
        )

        let expectedCachedURL = URL(
            string: "data:sample/RevenueCat/mock-checksum-value-someurl.mp4"
        ).unsafelyUnwrapped

        XCTAssertEqual(sut.networkService.invocations, [someURL])
        XCTAssertEqual(
            sut.cache.saveDataInvocations,
            [.init(data: data, url: expectedCachedURL, checksum: checksum)]
        )
        XCTAssertEqual(result, expectedCachedURL)
        XCTAssertNotEqual(someURL, expectedCachedURL)
    }

    func test_dataValidChecksum_savesAndReturns() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".asData
        let checksum = Checksum.generate(from: data, with: .md5)

        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        let url = try await sut.fileRepository
            .generateOrGetCachedFileURL(for: someURL, withChecksum: checksum)

        XCTAssertEqual(sut.networkService.invocations.count, 1)
        XCTAssertEqual(sut.cache.saveDataInvocations.count, 1)
        XCTAssertEqual(url, sut.cache.saveDataInvocations.first?.url)
        XCTAssertEqual(sut.cache.saveDataInvocations.first?.checksum, checksum)
    }

    func test_whenChecksumMismatch_throwsChecksumMismatch() async throws {
        let sut = await makeSystemUnderTest()
        let checksum = Checksum(algorithm: .sha256, value: "expected-hash")
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        sut.cache.stubSaveData(with: .failure(Checksum.ChecksumValidationFailure()))

        do {
            _ = try await sut.fileRepository.generateOrGetCachedFileURL(
                for: someURL,
                withChecksum: checksum
            )
            XCTFail("Expected checksumMismatch error")
        } catch {
            switch error as? FileRepository.Error {
            case .checksumMismatch:
                break
            default:
                XCTFail("Expected checksumMismatch, got \(error)")
            }
        }

        XCTAssertEqual(sut.cache.saveDataInvocations.first?.checksum, checksum)
    }

    func test_urlSessionDownloadFile_savesResponseToTemporaryFile() async throws {
        let expectedData = Data("downloaded content".utf8)
        MockFileDownloadURLProtocol.handler = { request in
            return (try Self.response(for: request, statusCode: 200), expectedData)
        }
        let session = self.fileDownloadSession()
        defer {
            session.invalidateAndCancel()
            MockFileDownloadURLProtocol.handler = nil
        }

        let downloadedURL = try await session.downloadFile(from: self.someURL)
        defer { try? FileManager.default.removeItem(at: downloadedURL) }

        XCTAssertEqual(try Data(contentsOf: downloadedURL), expectedData)
    }

    func test_urlSessionDownloadFile_rejectsNonSuccessfulResponse() async throws {
        MockFileDownloadURLProtocol.handler = { request in
            return (try Self.response(for: request, statusCode: 404), Data("not found".utf8))
        }
        let session = self.fileDownloadSession()
        defer {
            session.invalidateAndCancel()
            MockFileDownloadURLProtocol.handler = nil
        }

        do {
            _ = try await session.downloadFile(from: self.someURL)
            XCTFail("Expected a bad server response")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .badServerResponse)
        }
    }

    func test_validateDownloadedFile_removesRejectedDownload() throws {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not found".utf8).write(to: temporaryURL)
        let response = try Self.response(for: URLRequest(url: self.someURL), statusCode: 500)

        XCTAssertThrowsError(try validatedDownloadedFileURL(temporaryURL, response: response))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporaryURL.path))
    }

    func test_urlSessionDownloadFile_savesValidatedFileToCache() async throws {
        let expectedData = Data("downloaded content".utf8)
        let checksum = Checksum.generate(from: expectedData, with: .sha256)
        MockFileDownloadURLProtocol.handler = { request in
            return (try Self.response(for: request, statusCode: 200), expectedData)
        }
        let session = self.fileDownloadSession()
        let basePath = "FileRepositoryTests-\(UUID().uuidString)"
        let repository = FileRepository(
            networkService: session,
            fileManager: FileManager.default,
            basePath: basePath
        )
        defer {
            session.invalidateAndCancel()
            MockFileDownloadURLProtocol.handler = nil
        }

        let cachedURL = try await repository.generateOrGetCachedFileURL(
            for: self.someURL,
            withChecksum: checksum
        )
        defer { try? FileManager.default.removeItem(at: cachedURL.deletingLastPathComponent()) }

        XCTAssertEqual(try Data(contentsOf: cachedURL), expectedData)
    }

    func test_validateDownloadedFile_acceptsHTTPBoundaryAndNonHTTPResponses() throws {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let response299 = try Self.response(for: URLRequest(url: self.someURL), statusCode: 299)
        let nonHTTPResponse = URLResponse(
            url: self.someURL,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )

        XCTAssertEqual(try validatedDownloadedFileURL(temporaryURL, response: response299), temporaryURL)
        XCTAssertEqual(try validatedDownloadedFileURL(temporaryURL, response: nonHTTPResponse), temporaryURL)
    }

    func test_validateDownloadedFile_rejectsHTTPRedirectBoundary() throws {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("redirect".utf8).write(to: temporaryURL)
        let response = try Self.response(for: URLRequest(url: self.someURL), statusCode: 300)

        XCTAssertThrowsError(try validatedDownloadedFileURL(temporaryURL, response: response))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporaryURL.path))
    }

    func makeSystemUnderTest(
        cacheDirectoryURL: URL? = URL(string: "data:sample"),
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> SystemUnderTest {

        let cache = createAndTrackForMemoryLeak(
            file: file,
            line: line,
            MockSimpleCache(cacheDirectory: cacheDirectoryURL)
        )
        let networkService = createAndTrackForMemoryLeak(
            file: file,
            line: line,
            MockSimpleNetworkService()
        )

        let subject = createAndTrackForMemoryLeak(
            file: file,
            line: line,
            FileRepository(networkService: networkService, fileManager: cache)
        )

        return SystemUnderTest(fileRepository: subject, cache: cache, networkService: networkService)
    }

    struct SystemUnderTest {
        let fileRepository: FileRepository
        let cache: MockSimpleCache
        let networkService: MockSimpleNetworkService
    }

    struct SampleError: Error { }

    private func fileDownloadSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockFileDownloadURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private static func response(for request: URLRequest, statusCode: Int) throws -> HTTPURLResponse {
        return try XCTUnwrap(HTTPURLResponse(
            url: try XCTUnwrap(request.url),
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ))
    }
}

private final class MockFileDownloadURLProtocol: URLProtocol {

    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(self.request)
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: data)
            self.client?.urlProtocolDidFinishLoading(self)
        } catch {
            self.client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
