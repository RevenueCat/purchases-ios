//
//  RemoteConfigManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

class RemoteConfigManager {

    private let remoteConfigAPI: RemoteConfigAPI
    private let topicFetcher: TopicFetcher

    init(
        remoteConfigAPI: RemoteConfigAPI,
        topicFetcher: TopicFetcher
    ) {
        self.remoteConfigAPI = remoteConfigAPI
        self.topicFetcher = topicFetcher
    }

    func updateRemoteConfigIfNeeded(
        isAppBackgrounded: Bool,
        completion: (@MainActor @Sendable (BackendError?) -> Void)?
    ) {
        Task {
            let result: Result<RemoteConfigResponse, BackendError> = await withCheckedContinuation { continuation in
                self.remoteConfigAPI.getRemoteConfig(isAppBackgrounded: isAppBackgrounded) { result in
                    continuation.resume(returning: result)
                }
            }

            let error: BackendError?
            switch result {
            case let .success(response):
                error = await self.handleResponse(response)
            case let .failure(backendError):
                Logger.error(Strings.remoteConfig.remote_config_fetch_error(backendError))
                error = backendError
            }

            if let completion {
                await MainActor.run { completion(error) }
            }
        }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension RemoteConfigManager: @unchecked Sendable {}

private extension RemoteConfigManager {

    func handleResponse(_ response: RemoteConfigResponse) async -> BackendError? {
        // WIP: pick source by weighted priority once WeightedSource is wired up (#3458 equivalent).
        let source = response.blobSources.first

        let tasks: [TopicTask] = response.manifest.topics.compactMap { topic, entries in
            guard let entry = entries[Self.defaultEntryID] else { return nil }
            return TopicTask(topic: topic, entryId: Self.defaultEntryID, entry: entry)
        }

        let referenced = self.buildReferenceSet(manifest: response.manifest)

        let firstError: BackendError?
        if let source, !tasks.isEmpty {
            firstError = await self.downloadTopics(tasks: tasks, source: source)
        } else {
            firstError = nil
        }

        if firstError == nil, source != nil, !tasks.isEmpty {
            await self.topicFetcher.cleanupUnreferencedTopics(referenced: referenced)
        }
        return firstError
    }

    func downloadTopics(
        tasks: [TopicTask],
        source: RemoteConfigResponse.BlobSource
    ) async -> BackendError? {
        await withTaskGroup(of: BackendError?.self) { group -> BackendError? in
            var iterator = tasks.makeIterator()

            for _ in 0..<min(Self.maxParallelTopicDownloads, tasks.count) {
                if let task = iterator.next() {
                    group.addTask {
                        await self.topicFetcher.fetchTopicIfNeeded(
                            topic: task.topic,
                            entryId: task.entryId,
                            topicEntry: task.entry,
                            source: source
                        )
                    }
                }
            }

            var firstError: BackendError?
            for await error in group {
                if let error, firstError == nil {
                    firstError = error
                }
                if let task = iterator.next() {
                    group.addTask {
                        await self.topicFetcher.fetchTopicIfNeeded(
                            topic: task.topic,
                            entryId: task.entryId,
                            topicEntry: task.entry,
                            source: source
                        )
                    }
                }
            }
            return firstError
        }
    }

    func buildReferenceSet(
        manifest: RemoteConfigResponse.Manifest
    ) -> [RemoteConfigResponse.Topic: Set<String>] {
        manifest.topics.mapValues { entries in
            Set(entries.values.map { $0.blobRef })
        }
    }

    struct TopicTask {
        let topic: RemoteConfigResponse.Topic
        let entryId: String
        let entry: RemoteConfigResponse.TopicEntry
    }

    static let defaultEntryID = "default"
    static let maxParallelTopicDownloads = 4

}
