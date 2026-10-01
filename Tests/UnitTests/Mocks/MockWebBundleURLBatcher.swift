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

    private let _invokedPublishCount: Atomic<Int> = .init(0)
    private let _invokedPublishOfferings: Atomic<Offerings?> = nil
    private let _invokedPublishWorkflowsByOfferingId: Atomic<[String: PublishedWorkflow]> = .init([:])
    private let _invokedPublishPresentedWorkflowIDs: Atomic<[String]> = .init([])

    var invokedPublishCount: Int {
        return self._invokedPublishCount.value
    }
    var invokedPublishOfferings: Offerings? {
        return self._invokedPublishOfferings.value
    }
    var invokedPublishWorkflowsByOfferingId: [String: PublishedWorkflow] {
        return self._invokedPublishWorkflowsByOfferingId.value
    }
    var invokedPublishPresentedWorkflowIDs: [String] {
        return self._invokedPublishPresentedWorkflowIDs.value
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publish(
        offerings: Offerings,
        workflowsByOfferingId: [String: PublishedWorkflow]
    ) async {
        self._invokedPublishCount.modify { $0 += 1 }
        self._invokedPublishOfferings.value = offerings
        self._invokedPublishWorkflowsByOfferingId.value = workflowsByOfferingId
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publishPresentedWorkflow(_ workflow: PublishedWorkflow) async {
        self._invokedPublishPresentedWorkflowIDs.modify { $0.append(workflow.id) }
    }

}
