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
    func publish(_ batches: [WebBundleScreenURLBatch]) async

}

extension WebBundleURLBatcherType {

    /// Extracts and publishes web-bundle URLs from an already decoded workflow.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publishWebBundles(in workflow: PublishedWorkflow) async {
        await self.publish(WebBundleURLBatcher.screenURLBatches(in: workflow))
    }

}

/// Publishes caller-ordered web-view entry URL batches one screen at a time to ``WebBundleEventBus``.
///
/// Each batch is every web-view URL on that screen so the receiver can cache a complete screen
/// instead of a partial one. Callers determine cross-workflow cache priority. Within a workflow,
/// ``screenURLBatches(in:)`` puts the initial screen first, its single-step fallback second, then
/// the remaining reachable screens in breadth-first order.
actor WebBundleURLBatcher: WebBundleURLBatcherType {

    static let shared = WebBundleURLBatcher()

    private let eventBus: WebBundleEventBus

    init(eventBus: WebBundleEventBus = .shared) {
        self.eventBus = eventBus
    }

    /// Publishes pre-extracted screen URL batches without retaining their decoded workflows.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publish(_ batches: [WebBundleScreenURLBatch]) async {
        await self.publishBatches(batches)
    }

}

/// The complete set of web-bundle entry URLs needed by one workflow screen.
struct WebBundleScreenURLBatch: Equatable, Sendable {

    let urls: [URLWithValidation]

}

extension WebBundleURLBatcher {

    /// Current offering, then each placement's offering in alphabetical placement-id order, then the
    /// placement fallback. First occurrence of an ID wins. A placement mapped to `null` is skipped.
    /// Missing offerings stay in the list so a later workflow lookup can still succeed.
    static func targetOfferingIds(from offerings: Offerings) -> [String] {
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

    /// Cache priority starts with `initial_step_id`, followed by `single_step_fallback_id`, because
    /// either can be among the first paywalls shown. Remaining screens follow in breadth-first graph
    /// order. `screens` and `steps` are lookup tables keyed by opaque IDs (`pw…` / nanoid), so their
    /// keys and display names do not determine priority. Other unreachable screens are omitted.
    static func screensInVisitOrder(for workflow: PublishedWorkflow) -> [WorkflowScreen] {
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

    /// One batch per prioritized screen that has web-view URLs. A screen's URLs stay together.
    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    static func screenURLBatches(in workflow: PublishedWorkflow) -> [WebBundleScreenURLBatch] {
        return Self.screensInVisitOrder(for: workflow).compactMap { screen in
            let urls = Self.uniqueURLs(screen.allCacheAssets.webBundles)
            return urls.isEmpty ? nil : .init(urls: urls)
        }
    }

    static func uniqueURLs(_ urls: [URLWithValidation]) -> [URLWithValidation] {
        var seen: Set<URL> = []
        return urls.filter { seen.insert($0.url).inserted }
    }

    static func nextStepIDs(from step: WorkflowStep) -> [String] {
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

        // Declared triggers first. Remaining keys have no guaranteed order.
        for actionID in step.triggerActions.keys where !seenActionIDs.contains(actionID) {
            appendStep(forActionID: actionID)
        }

        return stepIDs
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension WebBundleURLBatcher {

    /// Each event is one screen's URLs in first-occurrence cache-priority order.
    func publishBatches(_ batches: [WebBundleScreenURLBatch]) async {
        guard !batches.isEmpty else { return }

        Logger.verbose(Strings.paywalls.warming_up_web_bundles(screenCount: batches.count))

        for batch in batches {
            await self.eventBus.publish(batch.urls)
        }
    }

}
