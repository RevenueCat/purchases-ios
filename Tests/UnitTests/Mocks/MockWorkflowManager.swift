//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWorkflowManager.swift
//
//  Created by RevenueCat.

import Foundation
@_spi(Internal) @testable import RevenueCat

class MockWorkflowManager: WorkflowManager, @unchecked Sendable {

    init() {
        super.init(backend: MockBackend(),
                   workflowsCache: WorkflowsCache(deviceCache: MockDeviceCache()),
                   paywallCache: nil,
                   operationDispatcher: MockOperationDispatcher())
    }

    var invokedGetWorkflowsList = false
    var invokedGetWorkflowsListCount = 0
    var invokedGetWorkflowsListParameters: (appUserID: String, isAppBackgrounded: Bool)?
    /// When `true`, the `onComplete` is captured instead of called so tests control its timing.
    var shouldStoreOnComplete = false
    private(set) var capturedOnComplete: (() -> Void)?

    override func getWorkflowsList(appUserID: String,
                                   isAppBackgrounded: Bool,
                                   onComplete: @escaping () -> Void) {
        self.invokedGetWorkflowsList = true
        self.invokedGetWorkflowsListCount += 1
        self.invokedGetWorkflowsListParameters = (appUserID, isAppBackgrounded)

        if self.shouldStoreOnComplete {
            self.capturedOnComplete = onComplete
        } else {
            onComplete()
        }
    }

    var invokedForceWorkflowsListCacheStale = false
    var invokedForceWorkflowsListCacheStaleCount = 0

    override func forceWorkflowsListCacheStale() {
        self.invokedForceWorkflowsListCacheStale = true
        self.invokedForceWorkflowsListCacheStaleCount += 1
    }

    /// Fires (and clears) the captured `onComplete`. Requires `shouldStoreOnComplete == true`.
    func completeStoredOnComplete() {
        let onComplete = self.capturedOnComplete
        self.capturedOnComplete = nil
        onComplete?()
    }

}
