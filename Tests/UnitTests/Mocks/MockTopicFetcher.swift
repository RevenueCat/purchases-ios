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

    enum Call: Equatable {
        case fetch
        case cleanup
    }

    let stubbedFetchResult: Atomic<BackendError?> = .init(nil)
    let fetchCalls: Atomic<[FetchCall]> = .init([])
    let cleanupCalls: Atomic<[[RemoteConfigResponse.Topic: Set<String>]]> = .init([])
    let callOrder: Atomic<[Call]> = .init([])

    convenience init() {
        self.init(fileManager: FileManager.default)
    }

    override func fetchTopicIfNeeded(
        topic: RemoteConfigResponse.Topic,
        entryId: String,
        topicEntry: RemoteConfigResponse.TopicEntry,
        source: RemoteConfigResponse.BlobSource
    ) async -> BackendError? {
        self.fetchCalls.modify {
            $0.append(FetchCall(topic: topic, entryId: entryId, topicEntry: topicEntry, source: source))
        }
        self.callOrder.modify { $0.append(.fetch) }
        return self.stubbedFetchResult.value
    }

    override func cleanupUnreferencedTopics(referenced: [RemoteConfigResponse.Topic: Set<String>]) async {
        self.cleanupCalls.modify { $0.append(referenced) }
        self.callOrder.modify { $0.append(.cleanup) }
    }

}
