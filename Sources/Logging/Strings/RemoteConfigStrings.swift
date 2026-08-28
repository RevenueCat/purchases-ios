//
//  RemoteConfigStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

enum RemoteConfigStrings {

    case audienceConfigurationDecodeFailed(Error)
    case cacheURLNotAvailable
    case checkpointAudiencesNotEvaluated(checkpointID: String, reason: String)
    case checkpointResolutionRepeatedlyStale(identifier: String)
    case checkpointResolutionRetry(identifier: String)
    case checkpointRuleSkipped(reason: String)
    case checkpointWorkflowRuleSkipped(workflowID: String, reason: String)
    case failedToClearBlobStore(Error)
    case failedToDeleteBlob(String, Error)
    case failedToReadBlob(String, Error)
    case failedToReadCache(Error)
    case failedToWriteBlob(String, Error)
    case failedToWriteCache
    case exhaustedBlobSources(String)
    case failedToBuildBlobURL(String)
    case failedToDownloadBlob(String, URL, Error)
    case duplicateSourceURL(String)
    case failedToParseResponse(Error)
    case malformedBlobRef(String)
    case mergeItemsBlobDataDisabled(topic: RemoteConfigTopic, itemKeys: [String])
    case mergeItemsBlobDataEmpty(topic: RemoteConfigTopic)
    case mergeItemsBlobDataUnavailableItems(topic: RemoteConfigTopic, itemKeys: [String])
    case notModified
    case prefetchEnqueued(Int)
    case prefetchingBlobCount(Int)
    case receivedConfiguration(activeTopics: [String], changedTopics: [String])
    case refreshing(domain: String, manifestPresent: Bool, isAppBackgrounded: Bool)
    case disablingRefresh(BackendError)
    case refreshFailed(BackendError)
    case refreshSkippedDisabled
    case skippingInvalidBlob(String)
    case persistedConfiguration(domain: String, activeTopicCount: Int, referencedBlobCount: Int)
    case sourceUnhealthy(ref: String, hasNextSource: Bool)
    case storedBlob(String, byteCount: Int, URL)
    case storedInlineBlob(String, byteCount: Int)
    case subscriberAttributesUnavailable(Error)
    case invalidDimensionName(String, parentPath: String)
    case uiConfigDecodeFailed(Error)
    case uiConfigMissingRequiredPart

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case let .audienceConfigurationDecodeFailed(error):
            return "Failed to decode canonical audience configuration: \(error.localizedDescription)"
        case .cacheURLNotAvailable:
            return "Remote config cache URL is not available."
        case let .checkpointAudiencesNotEvaluated(checkpointID, reason):
            return "The audiences for checkpoint '\(checkpointID)' could not be evaluated: \(reason)."
        case let .checkpointResolutionRepeatedlyStale(identifier):
            return "Remote configuration kept changing while resolving checkpoint '\(identifier)'."
        case let .checkpointResolutionRetry(identifier):
            return "Remote configuration changed while resolving checkpoint '\(identifier)'; resolving it again."
        case let .checkpointRuleSkipped(reason):
            return "Skipping malformed checkpoint rule: \(reason)."
        case let .checkpointWorkflowRuleSkipped(workflowID, reason):
            return "Skipping checkpoint rule for workflow '\(workflowID)': \(reason)."
        case let .failedToClearBlobStore(error):
            return "Failed to clear remote config blob store: \(error.localizedDescription)"
        case let .failedToDeleteBlob(ref, error):
            return "Failed to delete unreferenced remote config blob '\(ref)': \(error.localizedDescription)"
        case let .failedToReadBlob(ref, error):
            return "Failed to read remote config blob '\(ref)' from disk: \(error.localizedDescription)"
        case let .failedToReadCache(error):
            return "Failed to read remote config cache from disk: \(error.localizedDescription)"
        case let .failedToWriteBlob(ref, error):
            return "Failed to write remote config blob '\(ref)' to disk: \(error.localizedDescription)"
        case .failedToWriteCache:
            return "Failed to write remote config cache to disk."
        case let .exhaustedBlobSources(ref):
            return "Failed to download remote config blob '\(ref)': all blob sources were exhausted."
        case let .failedToBuildBlobURL(ref):
            return "Failed to build remote config blob URL for ref '\(ref)'."
        case let .failedToDownloadBlob(ref, url, error):
            return "Failed to download remote config blob '\(ref)' from \(url.absoluteString): " +
                "\(error.localizedDescription)"
        case let .duplicateSourceURL(url):
            return "Found remote config sources sharing the same URL with conflicting priority/weight " +
                "(\(url)). Keeping the highest-priority one (lowest priority number), tie-broken by weight."
        case let .failedToParseResponse(error):
            return "Failed to parse remote config response. Keeping cached configuration. Error: " +
            "\(error.localizedDescription)"
        case let .malformedBlobRef(ref):
            return "Refusing remote config blob operation with malformed ref '\(ref)'."
        case let .mergeItemsBlobDataDisabled(topic, itemKeys):
            return "Unable to merge remote config blob data for topic '\(topic.wireName)': " +
                "remote config is disabled. Requested item keys: \(itemKeys.sorted().joined(separator: ", "))."
        case let .mergeItemsBlobDataEmpty(topic):
            return "Unable to merge remote config blob data for topic '\(topic.wireName)': no item keys requested."
        case let .mergeItemsBlobDataUnavailableItems(topic, itemKeys):
            return "Unable to merge remote config blob data for topic '\(topic.wireName)': " +
                "unavailable item keys: \(itemKeys.sorted().joined(separator: ", "))."
        case .notModified:
            return "Remote config was not modified. Keeping cached configuration."
        case let .prefetchEnqueued(count):
            return "Enqueued \(count) remote config blob prefetch downloads."
        case let .prefetchingBlobCount(count):
            return "Prefetching \(count) remote config blobs requested by the latest configuration."
        case let .receivedConfiguration(activeTopics, changedTopics):
            return "Received remote config with \(activeTopics.count) active topics " +
                "(\(activeTopics.sorted().joined(separator: ", "))) and \(changedTopics.count) changed topics " +
                "(\(changedTopics.sorted().joined(separator: ", ")))."
        case let .refreshing(domain, manifestPresent, isAppBackgrounded):
            return "Refreshing remote config for domain '\(domain)' " +
                "(manifestPresent: \(manifestPresent), isAppBackgrounded: \(isAppBackgrounded))."
        case let .disablingRefresh(error):
            return "Disabling remote config for this session after receiving a 4xx response. Error: \(error)"
        case let .refreshFailed(error):
            return "Remote config refresh failed. Keeping cached configuration. Error: \(error)"
        case .refreshSkippedDisabled:
            return "Remote config is disabled for this session (4xx). Skipping refresh."
        case let .skippingInvalidBlob(ref):
            return "Skipping remote config blob '\(ref)': checksum verification failed."
        case let .persistedConfiguration(domain, activeTopicCount, referencedBlobCount):
            return "Persisted remote config for domain '\(domain)' with \(activeTopicCount) active topics " +
                "and \(referencedBlobCount) referenced blobs."
        case let .sourceUnhealthy(ref, hasNextSource):
            return "Marked remote config blob source unhealthy while downloading blob '\(ref)' " +
                "(hasNextSource: \(hasNextSource))."
        case let .storedBlob(ref, byteCount, url):
            return "Stored remote config blob '\(ref)' with \(byteCount) bytes downloaded from \(url.absoluteString)."
        case let .storedInlineBlob(ref, byteCount):
            return "Stored inline remote config blob '\(ref)' with \(byteCount) bytes."
        case let .subscriberAttributesUnavailable(error):
            return "The subscriber attributes are unavailable, so they cannot be evaluated: \(error)."
        case let .invalidDimensionName(name, parentPath):
            return "Ignoring dimension name '\(name)' under '\(parentPath)': " +
                "a dimension name cannot be empty, whitespace-only, or contain '.'."
        case let .uiConfigDecodeFailed(error):
            return "Failed to decode merged ui_config: \(error.localizedDescription)"
        case .uiConfigMissingRequiredPart:
            return "Failed to assemble ui_config: one or more parts are unavailable."
        }
    }

    var category: String { return "remote_config" }

}
