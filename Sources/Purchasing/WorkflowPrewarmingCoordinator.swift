//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPrewarmingCoordinator.swift
//
//  Created by Rick van der Linden on 11/3/26.

/// Coordinates workflow body caching, transient decoding, web-bundle publication, and asset prewarming.
final class WorkflowPrewarmingCoordinator: @unchecked Sendable {

    private let workflowsConfigProvider: WorkflowsConfigProviderType
    private let paywallCache: PaywallCacheWarmingType?
    private let operationDispatcher: OperationDispatcher
    private let webBundleURLBatcher: WebBundleURLBatcherType
    private let decodeCoordinator: WorkflowPrewarmingDecodeCoordinator
    private let webBundlePublicationTracker = WorkflowWebBundlePublicationTracker()
    private let backgroundPrewarmingLimiter = AsyncConcurrencyLimiter(maxConcurrentOperations: 1)

    init(
        workflowsConfigProvider: WorkflowsConfigProviderType,
        paywallCache: PaywallCacheWarmingType?,
        operationDispatcher: OperationDispatcher,
        webBundleURLBatcher: WebBundleURLBatcherType,
        decodeCoordinator: WorkflowPrewarmingDecodeCoordinator
    ) {
        self.workflowsConfigProvider = workflowsConfigProvider
        self.paywallCache = paywallCache
        self.operationDispatcher = operationDispatcher
        self.webBundleURLBatcher = webBundleURLBatcher
        self.decodeCoordinator = decodeCoordinator
    }

    /// Ensures the provider has cached the selected workflows' raw body data before scheduling transient decoding,
    /// URL publication, and asset prewarming.
    /// Only body-data readiness is awaited; decoding and downloads never delay offerings delivery.
    func schedulePrewarming(offerings: Offerings) async {
        let workflowIDsReadyForPrewarming = await self.workflowsConfigProvider.cachePrefetchedWorkflowBodyData(
            includingOfferingId: offerings.current?.identifier
        )

        self.operationDispatcher.dispatchOnWorkerThread { [weak self] in
            guard let self else { return }
            guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else { return }
            await self.backgroundPrewarmingLimiter.perform {
                await self.prewarm(
                    offerings: offerings,
                    workflowIDsForAssetPrewarming: workflowIDsReadyForPrewarming
                )
            }
        }
    }

    /// Publishes web-bundle URLs and pre-downloads assets from an already decoded workflow.
    func scheduleAssetPrewarming(for result: WorkflowDataResult) {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *), let paywallCache else { return }

        let webBundleURLBatcher = self.webBundleURLBatcher
        self.operationDispatcher.dispatchOnWorkerThread {
            await webBundleURLBatcher.publishWebBundles(in: result.workflow)
            await paywallCache.prewarmWorkflowAssets(workflow: result.workflow, uiConfig: result.uiConfig)
        }
    }

}

private extension WorkflowPrewarmingCoordinator {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func prewarm(offerings: Offerings, workflowIDsForAssetPrewarming: [String]) async {
        let configGeneration = self.workflowsConfigProvider.configGeneration
        let assetWorkflowIDs = Set(workflowIDsForAssetPrewarming)
        var handledAssetWorkflowIDs: Set<String> = []
        var resolvedTargetWorkflowIDs: Set<String> = []

        for offeringId in WebBundleURLBatcher.targetOfferingIds(from: offerings) {
            guard let workflowId = await self.workflowsConfigProvider.workflowId(forOfferingId: offeringId) else {
                continue
            }
            guard resolvedTargetWorkflowIDs.insert(workflowId).inserted else { continue }

            let shouldPrewarmAssets = assetWorkflowIDs.contains(workflowId)
                ? await self.shouldPrepareAssetPrewarming(for: workflowId)
                : false
            if shouldPrewarmAssets {
                handledAssetWorkflowIDs.insert(workflowId)
            }
            let shouldPublishWebBundles = await self.webBundlePublicationTracker.claimIfNeeded(
                workflowId,
                configGeneration: configGeneration
            )

            if let task = await self.decodeAndSchedulePrewarming(
                workflowId,
                shouldPrewarmAssets: shouldPrewarmAssets,
                shouldPublishWebBundles: shouldPublishWebBundles,
                configGeneration: configGeneration
            ) {
                await withTaskCancellationHandler {
                    await task.value
                } onCancel: {
                    task.cancel()
                }
            }
        }

        await self.prewarmRemainingAssetWorkflows(
            workflowIDsForAssetPrewarming,
            excluding: handledAssetWorkflowIDs
        )
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func decodeAndSchedulePrewarming(
        _ workflowId: String,
        shouldPrewarmAssets: Bool,
        shouldPublishWebBundles: Bool,
        configGeneration: Int
    ) async -> Task<Void, Never>? {
        guard shouldPrewarmAssets || shouldPublishWebBundles else { return nil }

        switch await self.decodeCoordinator.decode(workflowId: workflowId, using: self.workflowsConfigProvider) {
        case let .success(result):
            let assetPrewarmingTask = shouldPrewarmAssets
                ? await self.paywallCache?.startWorkflowAssetPrewarming(
                    workflow: result.workflow,
                    uiConfig: result.uiConfig
                )
                : nil
            if shouldPublishWebBundles {
                await self.webBundleURLBatcher.publishWebBundles(in: result.workflow)
                await self.completeWebBundlePublication(
                    workflowId,
                    published: true,
                    configGeneration: configGeneration
                )
            }
            return assetPrewarmingTask
        case let .failure(error):
            if shouldPublishWebBundles {
                await self.completeWebBundlePublication(
                    workflowId,
                    published: false,
                    configGeneration: configGeneration
                )
            }
            self.logAssetPrewarmingFailure(ifNeeded: shouldPrewarmAssets, workflowId: workflowId, error: error)
            return nil
        }
    }

    func completeWebBundlePublication(_ workflowId: String, published: Bool, configGeneration: Int) async {
        await self.webBundlePublicationTracker.completeClaims(
            [workflowId],
            publishedWorkflowIDs: published ? [workflowId] : [],
            configGeneration: configGeneration
        )
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func prewarmRemainingAssetWorkflows(
        _ workflowIDs: [String],
        excluding handledWorkflowIDs: Set<String>
    ) async {
        for workflowId in workflowIDs where !handledWorkflowIDs.contains(workflowId) {
            guard await self.shouldPrepareAssetPrewarming(for: workflowId) else { continue }
            guard let task = await self.decodeAndStartAssetPrewarming(workflowId) else { continue }

            await withTaskCancellationHandler {
                await task.value
            } onCancel: {
                task.cancel()
            }
        }
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func decodeAndStartAssetPrewarming(_ workflowId: String) async -> Task<Void, Never>? {
        switch await self.decodeCoordinator.decode(workflowId: workflowId, using: self.workflowsConfigProvider) {
        case let .success(result):
            return await self.paywallCache?.startWorkflowAssetPrewarming(
                workflow: result.workflow,
                uiConfig: result.uiConfig
            )
        case let .failure(error):
            self.logAssetPrewarmingFailure(workflowId: workflowId, error: error)
            return nil
        }
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func shouldPrepareAssetPrewarming(for workflowId: String) async -> Bool {
        guard let paywallCache else { return false }
        return !(await paywallCache.hasStartedWorkflowAssetPrewarming(for: workflowId))
    }

    func logAssetPrewarmingFailure(workflowId: String, error: WorkflowResolutionError) {
        Logger.debug(Strings.paywalls.workflow_resolution_for_asset_prewarming_failed(
            workflowId: workflowId,
            error: error
        ))
    }

    func logAssetPrewarmingFailure(
        ifNeeded: Bool,
        workflowId: String,
        error: WorkflowResolutionError
    ) {
        guard ifNeeded else { return }
        self.logAssetPrewarmingFailure(workflowId: workflowId, error: error)
    }

}

/// Remembers which workflows already had their web-bundle URLs published for the current config.
private actor WorkflowWebBundlePublicationTracker {

    private var configGeneration: Int?
    private var claimedWorkflowIDs: Set<String> = []
    private var publishedWorkflowIDs: Set<String> = []

    func claimIfNeeded(_ workflowId: String, configGeneration: Int) -> Bool {
        guard self.prepareForConfigGeneration(configGeneration),
              !self.claimedWorkflowIDs.contains(workflowId),
              !self.publishedWorkflowIDs.contains(workflowId) else {
            return false
        }

        self.claimedWorkflowIDs.insert(workflowId)
        return true
    }

    func completeClaims(
        _ claimedWorkflowIDs: Set<String>,
        publishedWorkflowIDs: Set<String>,
        configGeneration: Int
    ) {
        guard self.configGeneration == configGeneration else { return }
        self.claimedWorkflowIDs.subtract(claimedWorkflowIDs)
        self.publishedWorkflowIDs.formUnion(publishedWorkflowIDs)
    }

    private func prepareForConfigGeneration(_ configGeneration: Int) -> Bool {
        guard self.configGeneration.map({ configGeneration >= $0 }) ?? true else { return false }
        guard self.configGeneration != configGeneration else { return true }

        self.configGeneration = configGeneration
        self.claimedWorkflowIDs.removeAll()
        self.publishedWorkflowIDs.removeAll()
        return true
    }

}
