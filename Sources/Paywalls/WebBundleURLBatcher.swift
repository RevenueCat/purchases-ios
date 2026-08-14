//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleURLBatcher.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/26.

import Foundation

protocol WebBundleURLBatcherType: Sendable {

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publish(
        offerings: Offerings,
        workflowsByOfferingId: [String: PublishedWorkflow]
    ) async

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publishPresentedWorkflow(_ workflow: PublishedWorkflow) async

}

/// Selects web-view entry URLs in the order a customer is likely to see them, then publishes one
/// batch per screen to ``WebBundleEventBus``.
///
/// Each batch is every web-view URL on that screen so the receiver can cache a complete screen
/// instead of a partial one. Batches are sent in visit order: current offering, then each
/// placement's offering, then the placement fallback. Prefetch-only workflows are not included.
/// Screen order is a BFS of the workflow graph.
actor WebBundleURLBatcher: WebBundleURLBatcherType {

    static let shared = WebBundleURLBatcher()

    private let eventBus: WebBundleEventBus
    private var publishedWorkflowIDs: Set<String> = []

    init(eventBus: WebBundleEventBus = .shared) {
        self.eventBus = eventBus
    }

    /// Publishes one complete-screen batch at a time from `offerings` and `workflowsByOfferingId`.
    ///
    /// Workflow IDs are unioned, not replaced: cache warming calls this with an empty map for inline
    /// V2 trees and must not clear load-path IDs used by ``publishPresentedWorkflow(_:)``.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publish(
        offerings: Offerings,
        workflowsByOfferingId: [String: PublishedWorkflow]
    ) async {
        self.publishedWorkflowIDs.formUnion(workflowsByOfferingId.values.map(\.id))
        await self.publishBatches(
            Self.orderedScreenURLBatches(
                offerings: offerings,
                workflowsByOfferingId: workflowsByOfferingId
            )
        )
    }

    /// Appends a presented workflow that was not already in the load-path set (dedup by workflow ID).
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publishPresentedWorkflow(_ workflow: PublishedWorkflow) async {
        guard self.publishedWorkflowIDs.insert(workflow.id).inserted else { return }
        await self.publishBatches(Self.screenURLBatches(in: workflow))
    }

}

extension WebBundleURLBatcher {

    /// Current offering, then each placement's offering in alphabetical placement-id order, then the
    /// placement fallback. First occurrence of an ID wins. A placement mapped to `null` is skipped.
    /// Missing offerings stay in the list so a later workflow lookup can still succeed.
    nonisolated static func targetOfferingIds(from offerings: Offerings) -> [String] {
        var ids: [String] = []
        var seen: Set<String> = []

        func append(_ id: String?) {
            guard let id, seen.insert(id).inserted else { return }
            ids.append(id)
        }

        append(offerings.currentOfferingID)

        if let placements = offerings.placements {
            for placementId in placements.offeringIdsByPlacement.keys.sorted() {
                guard let offeringId: String? = placements.offeringIdsByPlacement[placementId] else {
                    continue
                }
                append(offeringId)
            }
            append(placements.fallbackOfferingId)
        }

        return ids
    }

    /// One batch per screen, in visit order. Workflows first (remote config), otherwise the
    /// offering's inline V2 tree as a single screen. Same workflow behind several offerings is
    /// enqueued once, at the first offering that mapped to it.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    nonisolated static func orderedScreenURLBatches(
        offerings: Offerings,
        workflowsByOfferingId: [String: PublishedWorkflow]
    ) -> [[URLWithValidation]] {
        var batches: [[URLWithValidation]] = []
        var seenWorkflowIDs: Set<String> = []

        for offeringId in Self.targetOfferingIds(from: offerings) {
            if let workflow = workflowsByOfferingId[offeringId] {
                guard seenWorkflowIDs.insert(workflow.id).inserted else { continue }
                batches.append(contentsOf: Self.screenURLBatches(in: workflow))
                continue
            }

            if let components = offerings.all[offeringId]?.internalPaywallComponents?.data {
                let urls = Self.uniqueURLs(components.allCacheAssets.webBundles)
                if !urls.isEmpty {
                    batches.append(urls)
                }
            }
        }

        return batches
    }

    /// Flattened visit-order URLs. First occurrence of a URL wins.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    nonisolated static func orderedWebViewURLs(
        offerings: Offerings,
        workflowsByOfferingId: [String: PublishedWorkflow]
    ) -> [URLWithValidation] {
        return Self.uniqueURLs(
            Self.orderedScreenURLBatches(
                offerings: offerings,
                workflowsByOfferingId: workflowsByOfferingId
            ).flatMap { $0 }
        )
    }

    /// BFS from `initial_step_id` then `single_step_fallback_id`. `screens` and `steps` are lookup
    /// tables keyed by opaque IDs (`pw…` / nanoid); visit order is the step graph, not key sort or
    /// display names. Unreachable screens are omitted.
    nonisolated static func screensInVisitOrder(for workflow: PublishedWorkflow) -> [WorkflowScreen] {
        var queue: [String] = [workflow.initialStepId]
        if let fallback = workflow.singleStepFallbackId, fallback != workflow.initialStepId {
            queue.append(fallback)
        }

        var visitedStepIDs: Set<String> = []
        var visitedScreenIDs: Set<String> = []
        var visitedScreens: [WorkflowScreen] = []

        while !queue.isEmpty {
            let stepID = queue.removeFirst()
            guard visitedStepIDs.insert(stepID).inserted else { continue }
            guard let step = workflow.steps[stepID] else { continue }

            if let screenID = step.screenId, let screen = workflow.screens[screenID] {
                if visitedScreenIDs.insert(screenID).inserted {
                    visitedScreens.append(screen)
                }
            }

            queue.append(contentsOf: Self.nextStepIDs(from: step))
        }

        return visitedScreens
    }

    /// One batch per visited screen that has web-view URLs. A screen's URLs stay together.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    nonisolated static func screenURLBatches(in workflow: PublishedWorkflow) -> [[URLWithValidation]] {
        return Self.screensInVisitOrder(for: workflow).compactMap { screen in
            let urls = Self.uniqueURLs(screen.allCacheAssets.webBundles)
            return urls.isEmpty ? nil : urls
        }
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    nonisolated static func webViewURLs(in workflow: PublishedWorkflow) -> [URLWithValidation] {
        return Self.uniqueURLs(Self.screenURLBatches(in: workflow).flatMap { $0 })
    }

    nonisolated static func uniqueURLs(_ urls: [URLWithValidation]) -> [URLWithValidation] {
        var seen: Set<URL> = []
        return urls.filter { seen.insert($0.url).inserted }
    }

    nonisolated static func nextStepIDs(from step: WorkflowStep) -> [String] {
        var seenActionIDs: Set<String> = []
        var stepIDs: [String] = []

        func appendStep(forActionID actionID: String) {
            guard case .step(let stepID) = step.triggerActions[actionID] else { return }
            stepIDs.append(stepID)
        }

        for trigger in step.triggers {
            guard let actionID = trigger.actionId else { continue }
            seenActionIDs.insert(actionID)
            appendStep(forActionID: actionID)
        }

        for actionID in step.triggerActions.keys where !seenActionIDs.contains(actionID) {
            appendStep(forActionID: actionID)
        }

        return stepIDs
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension WebBundleURLBatcher {

    func publishBatches(_ batches: [[URLWithValidation]]) async {
        guard !batches.isEmpty else { return }

        Logger.verbose(Strings.paywalls.warming_up_web_bundles(screenCount: batches.count))

        for batch in batches {
            await self.eventBus.publish(Set(batch))
        }
    }

}
