//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPrewarmingWorkload.swift
//

import CryptoKit
import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

final class WorkflowPrewarmingWorkload {

    private let manager: RemoteConfigManager
    private let rootURL: URL
    private let expectedWorkflowCount: Int
    private var offeringIDs: [String] = []
    private var expectedScreens: [String: Set<String>] = [:]
    private(set) var sha256 = ""

    private init(manager: RemoteConfigManager, rootURL: URL, expectedWorkflowCount: Int) {
        self.manager = manager
        self.rootURL = rootURL
        self.expectedWorkflowCount = expectedWorkflowCount
    }

    static func load(
        sourceFixture: String = "performance-benchmark-1-revision-24",
        workflowCount: Int = 1
    ) async throws -> WorkflowPrewarmingWorkload {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = try PerformanceFixture.makeManager(
            rootURL: rootURL,
            sourceFixture: sourceFixture,
            workflowCount: workflowCount
        )
        let workload = WorkflowPrewarmingWorkload(
            manager: manager,
            rootURL: rootURL,
            expectedWorkflowCount: workflowCount
        )
        do {
            try await workload.prepare()
            return workload
        } catch {
            workload.close()
            throw error
        }
    }

    private func prepare() async throws {
        let workflows = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows)
        let topic = try XCTUnwrap(workflows)
        self.offeringIDs = Set(topic.values.compactMap { item in
            guard case let .string(identifier)? = item.content["offering_identifier"] else { return nil }
            return identifier
        }).sorted()
        XCTAssertEqual(self.offeringIDs.count, self.expectedWorkflowCount, "The fixture needs every mapped workflow.")

        let provider = WorkflowsConfigProvider(manager: self.manager)
        var fingerprint = SHA256()
        for offeringID in self.offeringIDs {
            let mappedID = await provider.workflowId(forOfferingId: offeringID)
            let workflowID = try XCTUnwrap(mappedID)
            let body = await self.manager.blobData(for: .workflows, itemKey: workflowID)
            let data = try XCTUnwrap(body)
            let workflow = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let screens = try XCTUnwrap(workflow["screens"] as? [String: Any])
            self.expectedScreens[workflowID] = Set(screens.keys)
            fingerprint.update(data: Data(offeringID.utf8))
            fingerprint.update(data: data)
        }
        let uiTopic = await self.manager.awaitTopicAndPrefetchBlobsReady(.uiConfig)
        for key in try XCTUnwrap(uiTopic).keys.sorted() {
            let body = await self.manager.blobData(for: .uiConfig, itemKey: key)
            fingerprint.update(data: try XCTUnwrap(body))
        }
        self.sha256 = fingerprint.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func close() {
        self.manager.close()
        try? FileManager.default.removeItem(at: self.rootURL)
    }

    func prepareIteration() async throws -> WorkflowPrewarmingIteration {
        let decodedScreens = Atomic<[String: Set<String>]>([:])
        let operationDispatcher = PerformanceOperationDispatcher()
        let uiConfigProvider = UiConfigProvider(manager: self.manager)
        let provider = WorkflowsConfigProvider(
            manager: self.manager,
            uiConfigProvider: uiConfigProvider,
            workflowDecoder: { data in
                let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
                decodedScreens.modify { $0[workflow.id] = Set(workflow.screens.keys) }
                return workflow
            }
        )
        for identifier in self.offeringIDs {
            _ = await provider.cachePrefetchedWorkflowBodyData(includingOfferingId: identifier)
        }
        let config = await uiConfigProvider.getUiConfig()
        _ = try XCTUnwrap(config)
        let manager = WorkflowManager(
            workflowsConfigProvider: provider,
            paywallCache: nil,
            operationDispatcher: operationDispatcher,
            webBundleURLBatcher: WebBundleURLBatcher(eventBus: WebBundleEventBus())
        )
        let offerings = self.makeOfferings()
        await manager.schedulePrewarming(offerings: offerings)
        return WorkflowPrewarmingIteration(
            manager: manager,
            operationDispatcher: operationDispatcher,
            decodedScreens: decodedScreens,
            expectedScreens: self.expectedScreens
        )
    }

    private func makeOfferings() -> Offerings {
        let offerings = self.offeringIDs.map {
            Offering(identifier: $0, serverDescription: $0, availablePackages: [], webCheckoutUrl: nil)
        }
        let response = OfferingsResponse(
            currentOfferingId: self.offeringIDs.first,
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: self.offeringIDs.first,
            placements: .init(
                fallbackOfferingId: nil,
                offeringIdsByPlacement: Dictionary(uniqueKeysWithValues: self.offeringIDs.map { ($0, $0) })
            ),
            targeting: nil,
            contents: .init(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

}

struct WorkflowPrewarmingIteration {
    let manager: WorkflowManager
    let operationDispatcher: PerformanceOperationDispatcher
    let decodedScreens: Atomic<[String: Set<String>]>
    let expectedScreens: [String: Set<String>]

    func run() async {
        await self.operationDispatcher.invokeDispatchedAsyncWorkerThreadBlock()
    }

    func validate() {
        XCTAssertEqual(self.decodedScreens.value, self.expectedScreens,
                       "Every workflow and screen must decode in every iteration.")
    }
}

final class PerformanceOperationDispatcher: OperationDispatcher, @unchecked Sendable {

    private let dispatchedAsyncWorkerThreadBlocks: Atomic<[@Sendable () async -> Void]> = .init([])

    @discardableResult
    override func dispatchOnWorkerThread(
        jitterableDelay delay: JitterableDelay = .none,
        priority: TaskPriority = .background,
        block: @escaping @Sendable () async -> Void
    ) -> Task<Void, Never> {
        self.dispatchedAsyncWorkerThreadBlocks.modify { $0.append(block) }
        return Task {}
    }

    func invokeDispatchedAsyncWorkerThreadBlock() async {
        let block = self.dispatchedAsyncWorkerThreadBlocks.modify { blocks -> (@Sendable () async -> Void)? in
            guard !blocks.isEmpty else { return nil }
            return blocks.removeFirst()
        }
        guard let block else {
            XCTFail("Expected a scheduled workflow prewarming pass.")
            return
        }
        await block()
    }

}
