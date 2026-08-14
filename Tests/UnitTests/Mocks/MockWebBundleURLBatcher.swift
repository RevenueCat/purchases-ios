//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWebBundleURLBatcher.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/26.

import Foundation
@_spi(Internal) @testable import RevenueCat

final class MockWebBundleURLBatcher: WebBundleURLBatcherType, @unchecked Sendable {

    struct PublishCall {
        let offerings: Offerings
        let workflowsByOfferingId: [String: PublishedWorkflow]
    }

    private let _publishCalls: Atomic<[PublishCall]> = .init([])
    private let _presentedWorkflows: Atomic<[PublishedWorkflow]> = .init([])

    var invokedPublish: Bool {
        return !self._publishCalls.value.isEmpty
    }
    var invokedPublishCount: Int {
        return self._publishCalls.value.count
    }
    var invokedPublishCalls: [PublishCall] {
        return self._publishCalls.value
    }
    var invokedPublishOfferings: Offerings? {
        return self._publishCalls.value.last?.offerings
    }
    var invokedPublishWorkflowsByOfferingId: [String: PublishedWorkflow]? {
        return self._publishCalls.value.last?.workflowsByOfferingId
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publish(
        offerings: Offerings,
        workflowsByOfferingId: [String: PublishedWorkflow]
    ) async {
        self._publishCalls.modify {
            $0.append(PublishCall(offerings: offerings, workflowsByOfferingId: workflowsByOfferingId))
        }
    }

    var invokedPublishPresentedWorkflow: Bool {
        return !self._presentedWorkflows.value.isEmpty
    }
    var invokedPublishPresentedWorkflowCount: Int {
        return self._presentedWorkflows.value.count
    }
    var invokedPublishPresentedWorkflowIDs: [String] {
        return self._presentedWorkflows.value.map(\.id)
    }
    var invokedPublishPresentedWorkflows: [PublishedWorkflow] {
        return self._presentedWorkflows.value
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publishPresentedWorkflow(_ workflow: PublishedWorkflow) async {
        self._presentedWorkflows.modify { $0.append(workflow) }
    }

}
