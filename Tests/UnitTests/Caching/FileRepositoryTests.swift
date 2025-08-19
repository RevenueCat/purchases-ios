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

@_spi(Internal) @testable import RevenueCat
import XCTest

@MainActor
class FileRepositoryTests: TestCase {
    let someURL = URL(string: "https://somesite.com/someurl").unsafelyUnwrapped

    func test_ifContentExists_networkServiceIsNotCalled() async throws {
        let sut = await makeSystemUnderTest()
        sut.cache.stubCachedContentExists(with: true)
        let data = try await sut.fileRepository.getCachedURL(for: someURL)

        XCTAssertNotNil(data)
        XCTAssertEqual(sut.networkService.invocations, [])
    }

    func test_prefetch_invokesNetwork() async throws {
        let sut = await makeSystemUnderTest()
        let data = "SomeData".data(using: .utf8).unsafelyUnwrapped

        sut.cache.stubSaveData(with: .success(.init(data: data, url: someURL)))
        sut.cache.stubCachedContentExists(with: false)
        sut.networkService.stubResponse(at: 0, result: .success(data))

        sut.fileRepository.prefetch(urls: [someURL])

        await yield()

        XCTAssertEqual(sut.networkService.invocations.count, 1)
    }

    func test_whenCacheURLCannotBeAssembled_returnsNil() async throws {
        let sut = await makeSystemUnderTest(cacheDirectoryURL: nil)
        do {
            _ = try await sut.fileRepository.getCachedURL(for: someURL)
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
            _ = try await sut.fileRepository.getCachedURL(for: someURL)
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
        let result = try await sut.fileRepository.getCachedURL(for: someURL)

        let expectedCachedURL = URL(string: "data:sample/someurl").unsafelyUnwrapped

        XCTAssertEqual(sut.networkService.invocations, [someURL])
        XCTAssertEqual(sut.cache.saveDataInvocations, [.init(data: data, url: expectedCachedURL)])
        XCTAssertEqual(result, expectedCachedURL)
        XCTAssertNotEqual(someURL, expectedCachedURL)
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
