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

    func testAssetOverrideChangesNetworkURLWithoutChangingCacheIdentity() async throws {
        let sut = await self.makeSystemUnderTest()
        let original = try XCTUnwrap(URL(string: "https://assets.pawwalls.com/image.heic"))
        let replacement = try XCTUnwrap(URL(string: "https://assets.8-lives-cat.io/image.heic"))
        let repository = FileRepository(
            networkService: sut.networkService,
            fileManager: sut.cache,
            assetURLResolver: { _ in [replacement] }
        )
        sut.cache.stubCachedContentExists(with: false)
        sut.cache.stubSaveData(with: .success(.init(data: "SomeData".asData, url: original)))
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))

        let result = try await repository.generateOrGetCachedFileURL(for: original, withChecksum: nil)

        XCTAssertEqual(sut.networkService.invocations, [replacement])
        XCTAssertEqual(result, repository.generateLocalFilesystemURL(forRemoteURL: original, withChecksum: nil))
        XCTAssertNotEqual(result, repository.generateLocalFilesystemURL(forRemoteURL: replacement, withChecksum: nil))
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

    func testNetworkFailureRetriesFallbackAndKeepsCanonicalCacheIdentity() async throws {
        let sut = await self.makeSystemUnderTest()
        let primary = try XCTUnwrap(URL(string: "https://assets.pawwalls.com/image.heic"))
        let backup = try XCTUnwrap(URL(string: "https://assets.8-lives-cat.io/image.heic"))
        let repository = FileRepository(networkService: sut.networkService, fileManager: sut.cache,
                                        assetURLResolver: { _ in [primary, backup] })
        sut.cache.stubCachedContentExists(with: false)
        sut.cache.stubSaveData(with: .success(.init(data: "valid".asData, url: primary)))
        sut.networkService.stubResponse(at: 0, result: .failure(URLError(.timedOut)))
        sut.networkService.stubResponse(at: 1, result: .success("valid"))

        let result = try await repository.generateOrGetCachedFileURL(for: primary, withChecksum: nil)

        XCTAssertEqual(sut.networkService.invocations, [primary, backup])
        XCTAssertEqual(result, repository.generateLocalFilesystemURL(forRemoteURL: primary, withChecksum: nil))
    }

    func testChecksumFailureRetriesFallbackButLocalWriteFailureDoesNot() async throws {
        let failures: [Swift.Error] = [Checksum.ChecksumValidationFailure(), CocoaError(.fileWriteOutOfSpace)]
        for failure in failures {
            let sut = await self.makeSystemUnderTest()
            let backup = try XCTUnwrap(URL(string: "https://assets.8-lives-cat.io/image.heic"))
            let primary = self.someURL
            let repository = FileRepository(networkService: sut.networkService, fileManager: sut.cache,
                                            assetURLResolver: { _ in [primary, backup] })
            sut.cache.stubCachedContentExists(with: false)
            sut.cache.stubSaveData(with: .failure(failure))
            sut.cache.stubSaveData(at: 1, with: .success(.init(data: "valid".asData, url: primary)))
            sut.networkService.stubResponse(at: 0, result: .success("corrupt"))
            sut.networkService.stubResponse(at: 1, result: .success("valid"))

            do {
                _ = try await repository.generateOrGetCachedFileURL(for: primary, withChecksum: nil)
                XCTAssertTrue(failure is Checksum.ChecksumValidationFailure)
            } catch {
                XCTAssertTrue(failure is CocoaError)
            }
            XCTAssertEqual(sut.networkService.invocations,
                           failure is CocoaError ? [primary] : [primary, backup])
        }
    }

    func testCancelledFileDownloadDoesNotTryFallback() async throws {
        let sut = await self.makeSystemUnderTest()
        let backup = try XCTUnwrap(URL(string: "https://assets.8-lives-cat.io/image.heic"))
        let primary = self.someURL
        let repository = FileRepository(networkService: sut.networkService, fileManager: sut.cache,
                                        assetURLResolver: { _ in [primary, backup] })
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .failure(URLError(.cancelled)))

        do {
            _ = try await repository.generateOrGetCachedFileURL(for: primary, withChecksum: nil)
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }
        XCTAssertEqual(sut.networkService.invocations, [primary])
        XCTAssertTrue(sut.cache.saveDataInvocations.isEmpty)
    }

    func testAllFailedFileSourcesAreAttemptedOnce() async throws {
        let sut = await self.makeSystemUnderTest()
        let backup = try XCTUnwrap(URL(string: "https://assets.8-lives-cat.io/image.heic"))
        let primary = self.someURL
        let repository = FileRepository(networkService: sut.networkService, fileManager: sut.cache,
                                        assetURLResolver: { _ in [primary, backup] })
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .failure(URLError(.badServerResponse)))
        sut.networkService.stubResponse(at: 1, result: .failure(URLError(.cannotConnectToHost)))

        do {
            _ = try await repository.generateOrGetCachedFileURL(for: primary, withChecksum: nil)
            XCTFail("Expected download failure")
        } catch {
            guard case FileRepository.Error.failedToFetchFileFromRemoteSource = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(sut.networkService.invocations, [primary, backup])
    }

    func testInterruptedStreamRetriesWithFreshBytesAndCachesOnlyTheValidFile() async throws {
        let name = UUID().uuidString
        let primary = try XCTUnwrap(URL(string: "https://assets.pawwalls.com/\(name).heic"))
        let backup = try XCTUnwrap(URL(string: "https://assets.8-lives-cat.io/\(name).heic"))
        let data = "complete image".asData
        let repository = FileRepository(
            networkService: InterruptedStreamService(primary: primary, data: data),
            fileManager: FileManager.default,
            basePath: "RevenueCat-CDN-Test-\(name)",
            assetURLResolver: { _ in [primary, backup] }
        )
        let cacheURL = try XCTUnwrap(repository.generateLocalFilesystemURL(forRemoteURL: primary, withChecksum: nil))
        defer { try? FileManager.default.removeItem(at: cacheURL.deletingLastPathComponent()) }

        let result = try await repository.generateOrGetCachedFileURL(for: primary, withChecksum: nil)

        XCTAssertEqual(result, cacheURL)
        XCTAssertEqual(try Data(contentsOf: result), data)
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
        sut.cache.stubCachedContentExists(with: false)
        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        let result = try await sut.fileRepository.generateOrGetCachedFileURL(
            for: someURL,
            withChecksum: .init(algorithm: .md5, value: "mock-checksum-value-")
        )

        let expectedCachedURL = URL(
            string: "data:sample/RevenueCat/mock-checksum-value-someurl.mp4"
        ).unsafelyUnwrapped

        XCTAssertEqual(sut.networkService.invocations, [someURL])
        XCTAssertEqual(sut.cache.saveDataInvocations, [.init(data: data, url: expectedCachedURL)])
        XCTAssertEqual(result, expectedCachedURL)
        XCTAssertNotEqual(someURL, expectedCachedURL)
    }

    func test_dataValidChecksum_savesAndReturns() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".asData

        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        let url = try await sut.fileRepository
            .generateOrGetCachedFileURL(for: someURL, withChecksum: Checksum.generate(from: data, with: .md5))

        XCTAssertEqual(sut.networkService.invocations.count, 1)
        XCTAssertEqual(sut.cache.saveDataInvocations.count, 1)
        XCTAssertEqual(url, sut.cache.saveDataInvocations.first?.url)
    }

    func test_whenChecksumMismatch_throwsChecksumMismatch() async throws {
        let sut = await makeSystemUnderTest()
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success("SomeData"))
        sut.cache.stubSaveData(with: .failure(Checksum.ChecksumValidationFailure()))

        do {
            _ = try await sut.fileRepository.generateOrGetCachedFileURL(
                for: someURL,
                withChecksum: .init(algorithm: .sha256, value: "expected-hash")
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
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
private struct InterruptedStreamService: SimpleNetworkServiceType {

    let primary: URL
    let data: Data

    func bytes(from url: URL) async throws -> AsyncThrowingStream<UInt8, Swift.Error> {
        return AsyncThrowingStream { continuation in
            if url == self.primary {
                continuation.yield(0)
                continuation.finish(throwing: URLError(.networkConnectionLost))
            } else {
                self.data.forEach { continuation.yield($0) }
                continuation.finish()
            }
        }
    }

}
