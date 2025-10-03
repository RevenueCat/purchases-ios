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
class FileRepositoryTests: TestCase {
    let someURL = URL(string: "https://somesite.com/someurl").unsafelyUnwrapped

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
        sut.networkService.stubResponse(at: 0, result: .success(data))

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
        sut.networkService.stubResponse(at: 0, result: .success(data))
        let result = try await sut.fileRepository.generateOrGetCachedFileURL(for: someURL, withChecksum: nil)

        let expectedCachedURL = URL(string: "data:sample/RevenueCat/e8a0d6b245a127f56629765a9815ba2c").unsafelyUnwrapped

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
        sut.networkService.stubResponse(at: 0, result: .success(data))
        let url = try await sut.fileRepository
            .generateOrGetCachedFileURL(for: someURL, withChecksum: Checksum.generate(from: data, with: .md5))

        await expect(sut.networkService.invocations.count).toEventually(equal(1))
        XCTAssertEqual(sut.cache.saveDataInvocations.count, 1)

    }

    func test_dataWithInvalidChecksum_doesNotSaveAndThrows() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".asData

        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success(data))
        do {
            _ = try await sut.fileRepository
                .generateOrGetCachedFileURL(
                    for: someURL,
                    withChecksum: Checksum.generate(from: "not matching data".asData, with: .md5)
                )
            XCTFail(#function)
        } catch {
            switch error as? FileRepository.Error {
            case .failedToFetchFileFromRemoteSource(let value):
                if !value.contains("ChecksumValidationFailure") {
                    fallthrough
                }
            default:
                XCTFail(#function)
            }
        }

        XCTAssertEqual(sut.cache.saveDataInvocations.count, 0)
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
