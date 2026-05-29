//
//  RemoteConfigManagerTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 28/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class RemoteConfigManagerTests: TestCase {

    private var remoteConfigAPI: MockRemoteConfigAPI!
    private var topicFetcher: MockTopicFetcher!
    private var manager: RemoteConfigManager!

    override func setUp() {
        super.setUp()
        self.remoteConfigAPI = MockRemoteConfigAPI()
        self.topicFetcher = MockTopicFetcher()
        self.manager = RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            topicFetcher: self.topicFetcher
        )
    }

    // MARK: - Happy path

    func testSingleTopicDelegatesToFetcherAndCompletesWithNil() {
        let src = makeSource(id: "primary")
        let entry = makeEntry(blobRef: "abc123def456")
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [src],
            topics: [.productEntitlementMapping: ["default": entry]]
        ))

        var receivedError: BackendError?
        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { error in
                receivedError = error
                done()
            }
        }

        expect(receivedError).to(beNil())
        expect(self.topicFetcher.fetchCalls).to(haveCount(1))
        let call = self.topicFetcher.fetchCalls.first
        expect(call?.topic).to(equal(.productEntitlementMapping))
        expect(call?.entryId).to(equal("default"))
        expect(call?.topicEntry).to(equal(entry))
        expect(call?.source).to(equal(src))
    }

    // MARK: - Empty / missing data

    func testEmptySourcesSkipsTopicFetcherAndCompletesWithNil() {
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [],
            topics: [.productEntitlementMapping: ["default": makeEntry(blobRef: "abc")]]
        ))

        var receivedError: BackendError?
        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { error in
                receivedError = error
                done()
            }
        }

        expect(receivedError).to(beNil())
        expect(self.topicFetcher.fetchCalls).to(beEmpty())
    }

    func testEmptyTopicsSkipsTopicFetcherAndCompletesWithNil() {
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [makeSource(id: "primary")],
            topics: [:]
        ))

        var receivedError: BackendError?
        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { error in
                receivedError = error
                done()
            }
        }

        expect(receivedError).to(beNil())
        expect(self.topicFetcher.fetchCalls).to(beEmpty())
    }

    func testTopicWithoutDefaultEntryIdIsSkipped() {
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [makeSource(id: "primary")],
            topics: [.productEntitlementMapping: ["EXPERIMENT_A": makeEntry(blobRef: "abc")]]
        ))

        var receivedError: BackendError?
        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { error in
                receivedError = error
                done()
            }
        }

        expect(receivedError).to(beNil())
        expect(self.topicFetcher.fetchCalls).to(beEmpty())
    }

    // MARK: - Source selection

    func testSelectsFirstSourceWhenMultipleAvailable() {
        let first = makeSource(id: "first")
        let second = makeSource(id: "second")
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [first, second],
            topics: [.productEntitlementMapping: ["default": makeEntry(blobRef: "abc")]]
        ))

        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { _ in done() }
        }

        expect(self.topicFetcher.fetchCalls.first?.source).to(equal(first))
    }

    // MARK: - Error propagation

    func testFetcherErrorIsForwardedToCompletion() {
        let fetcherError = BackendError.networkError(.networkError(
            NSError(domain: "test", code: -1, userInfo: nil)
        ))
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [makeSource(id: "primary")],
            topics: [.productEntitlementMapping: ["default": makeEntry(blobRef: "abc")]]
        ))
        self.topicFetcher.stubbedFetchResult = fetcherError

        var receivedError: BackendError?
        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { error in
                receivedError = error
                done()
            }
        }

        expect(receivedError).toNot(beNil())
    }

    func testBackendErrorShortCircuitsBeforeFetcher() {
        let backendError = BackendError.networkError(.networkError(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        ))
        self.remoteConfigAPI.stubbedResult = .failure(backendError)

        var receivedError: BackendError?
        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false) { error in
                receivedError = error
                done()
            }
        }

        expect(receivedError).toNot(beNil())
        expect(self.topicFetcher.fetchCalls).to(beEmpty())
    }

    // MARK: - isAppBackgrounded forwarding

    func testIsAppBackgroundedIsForwardedToAPI() {
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(sources: [], topics: [:]))

        waitUntil { done in
            self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: true) { _ in done() }
        }

        expect(self.remoteConfigAPI.invokedIsAppBackgrounded).to(beTrue())
    }

    // MARK: - Nil completion

    func testNilCompletionDoesNotCrash() {
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [makeSource(id: "primary")],
            topics: [.productEntitlementMapping: ["default": makeEntry(blobRef: "abc")]]
        ))

        self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false, completion: nil)

        expect(self.topicFetcher.fetchCalls).toEventually(haveCount(1))
    }

    func testFetchRunsEvenWithNilCompletion() {
        let src = makeSource(id: "primary")
        let entry = makeEntry(blobRef: "abc")
        self.remoteConfigAPI.stubbedResult = .success(makeResponse(
            sources: [src],
            topics: [.productEntitlementMapping: ["default": entry]]
        ))

        self.manager.updateRemoteConfigIfNeeded(isAppBackgrounded: false, completion: nil)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount).toEventually(equal(1))
        expect(self.topicFetcher.fetchCalls).toEventually(haveCount(1))
    }

}

// MARK: - Helpers

private extension RemoteConfigManagerTests {

    func makeSource(id: String) -> RemoteConfigResponse.BlobSource {
        RemoteConfigResponse.BlobSource(
            id: id,
            urlFormat: "https://assets.example.com/{blob_ref}",
            priority: 0,
            weight: 100
        )
    }

    func makeEntry(blobRef: String) -> RemoteConfigResponse.TopicEntry {
        RemoteConfigResponse.TopicEntry(blobRef: blobRef)
    }

    func makeResponse(
        sources: [RemoteConfigResponse.BlobSource],
        topics: [RemoteConfigResponse.Topic: [String: RemoteConfigResponse.TopicEntry]]
    ) -> RemoteConfigResponse {
        RemoteConfigResponse(
            blobSources: sources,
            manifest: RemoteConfigResponse.Manifest(topics: topics)
        )
    }

}
