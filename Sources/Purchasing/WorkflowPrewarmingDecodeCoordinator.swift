//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPrewarmingDecodeCoordinator.swift
//
//  Created by Rick van der Linden on 10/28/26.
//

import Foundation

/// Shares overlapping workflow prewarming decodes and limits how many run at once.
/// Completed decodes are not cached.
actor WorkflowPrewarmingDecodeCoordinator {

    private struct InFlightDecode {
        let identifier: UUID
        let task: Task<Result<WorkflowDataResult, WorkflowResolutionError>, Never>
    }

    private struct DecodeID: Hashable {
        let workflowId: String
        let configGeneration: Int
    }

    private let decodeLimiter: DecodeLimiter
    private var inFlightDecodes: [DecodeID: InFlightDecode] = [:]
    private(set) var activeRequestCount = 0

    init(maxConcurrentDecodes: Int = 4) {
        self.decodeLimiter = .init(maxConcurrentDecodes: maxConcurrentDecodes)
    }

    /// Shares only active work from the same config generation. Completed graphs are released instead of becoming
    /// another workflow cache. Distinct decodes are limited to four at a time to bound CPU and peak memory.
    func decode(
        workflowId: String,
        using provider: WorkflowsConfigProviderType
    ) async -> Result<WorkflowDataResult, WorkflowResolutionError> {
        let decodeID = DecodeID(
            workflowId: workflowId,
            configGeneration: provider.configGeneration
        )

        self.activeRequestCount += 1
        defer { self.activeRequestCount -= 1 }

        if let inFlightDecode = self.inFlightDecodes[decodeID] {
            return await inFlightDecode.task.value
        }

        let identifier = UUID()
        let decodeLimiter = self.decodeLimiter
        let task = Task {
            await decodeLimiter.acquire()
            let result = await provider.decodeCachedWorkflowForAssetPrewarming(workflowId: workflowId)
            await decodeLimiter.release()
            return result
        }
        self.inFlightDecodes[decodeID] = InFlightDecode(identifier: identifier, task: task)

        let result = await task.value
        if self.inFlightDecodes[decodeID]?.identifier == identifier {
            self.inFlightDecodes[decodeID] = nil
        }
        return result
    }

    private actor DecodeLimiter {

        private var availablePermits: Int
        private var waiters: [CheckedContinuation<Void, Never>] = []

        init(maxConcurrentDecodes: Int) {
            precondition(maxConcurrentDecodes > 0)
            self.availablePermits = maxConcurrentDecodes
        }

        func acquire() async {
            guard self.availablePermits == 0 else {
                self.availablePermits -= 1
                return
            }

            await withCheckedContinuation { continuation in
                self.waiters.append(continuation)
            }
        }

        func release() {
            guard !self.waiters.isEmpty else {
                self.availablePermits += 1
                return
            }

            self.waiters.removeFirst().resume()
        }

    }

}
