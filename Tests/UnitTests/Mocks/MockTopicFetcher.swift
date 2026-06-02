//
//  MockTopicFetcher.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 28/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

@testable import RevenueCat

class MockTopicFetcher: TopicFetcher {

    struct FetchCall {
        let topic: RemoteConfigResponse.Topic
        let entryId: String
        let topicEntry: RemoteConfigResponse.TopicEntry
        let source: RemoteConfigResponse.BlobSource
    }

    var stubbedFetchResult: BackendError?
    var fetchCalls: [FetchCall] = []

    convenience init() {
        // Downloader is never exercised: `fetchTopicIfNeeded` is overridden below.
        self.init(fileManager: FileManager.default, downloader: URLSessionBlobDownloader())
    }

    override func fetchTopicIfNeeded(
        topic: RemoteConfigResponse.Topic,
        entryId: String,
        topicEntry: RemoteConfigResponse.TopicEntry,
        source: RemoteConfigResponse.BlobSource
    ) async -> BackendError? {
        self.fetchCalls.append(FetchCall(topic: topic, entryId: entryId, topicEntry: topicEntry, source: source))
        return self.stubbedFetchResult
    }

}
