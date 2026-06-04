//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsAPI.swift
//
//  Created by RevenueCat.

import Foundation

class WorkflowsAPI {

    typealias WorkflowDetailResponseHandler = Backend.ResponseHandler<WorkflowDataResult>
    typealias WorkflowsListResponseHandler = Backend.ResponseHandler<WorkflowsListResponse>

    private let workflowDetailCallbackCache: CallbackCache<WorkflowDetailCallback>
    private let workflowsListCallbackCache: CallbackCache<WorkflowsListCallback>
    private let backendConfig: BackendConfiguration
    private let detailProcessor: WorkflowDetailProcessor

    init(backendConfig: BackendConfiguration,
         cdnFetch: WorkflowCdnFetch? = nil) {
        self.backendConfig = backendConfig
        self.workflowDetailCallbackCache = .init()
        self.workflowsListCallbackCache = .init()
        self.detailProcessor = WorkflowDetailProcessor(
            cdnFetch: cdnFetch ?? Self.defaultCdnFetch(httpClient: backendConfig.httpClient)
        )
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private static let workflowsFileRepository = FileRepository(basePath: "RevenueCat/workflows")

    private static func defaultCdnFetch(httpClient: HTTPClient) -> WorkflowCdnFetch {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return Self.fileCachedCdnFetch(fileRepository: Self.workflowsFileRepository)
        }
        return Self.httpCdnFetch(httpClient: httpClient)
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    private static func fileCachedCdnFetch(
        fileRepository: FileRepositoryType
    ) -> WorkflowCdnFetch {
        return { cdnUrl, hash, completion in
            guard let url = URL(string: cdnUrl) else {
                completion(.failure(URLError(.badURL)))
                return
            }
            let checksum = hash.map { Checksum(algorithm: .sha256, value: $0) }
            Task {
                do {
                    let cachedURL = try await fileRepository.generateOrGetCachedFileURL(
                        for: url,
                        withChecksum: checksum
                    )
                    completion(.success(try Data(contentsOf: cachedURL)))
                } catch FileRepository.Error.checksumMismatch {
                    completion(.failure(WorkflowDetailProcessingError.cdnHashMismatch))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func httpCdnFetch(httpClient: HTTPClient) -> WorkflowCdnFetch {
        return { cdnUrl, _, completion in
            guard let url = URL(string: cdnUrl) else {
                completion(.failure(URLError(.badURL)))
                return
            }
            httpClient.fetchRawData(from: url, completion: completion)
        }
    }

    func getWorkflows(appUserID: String,
                      isAppBackgrounded: Bool,
                      type: String? = nil,
                      completion: @escaping WorkflowsListResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWorkflowsListOperation.createFactory(
            configuration: config,
            callbackCache: self.workflowsListCallbackCache,
            type: type
        )

        let callback = WorkflowsListCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.workflowsListCallbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

    func getWorkflow(appUserID: String,
                     workflowId: String,
                     isAppBackgrounded: Bool,
                     completion: @escaping WorkflowDetailResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWorkflowOperation.createFactory(
            configuration: config,
            workflowId: workflowId,
            detailProcessor: self.detailProcessor,
            workflowDetailCallbackCache: self.workflowDetailCallbackCache
        )

        let callback = WorkflowDetailCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.workflowDetailCallbackCache.add(callback)

        // Detail fetches run on the dedicated workflows queue so their CDN asset downloads overlap
        // (up to 4) instead of serializing on the single serial backend queue. The list fetch above
        // stays on the serial queue.
        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus,
            queue: self.backendConfig.workflowsQueue
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WorkflowsAPI: @unchecked Sendable {}
