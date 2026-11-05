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
    private var offeringIDs: [String] = []
    private var expectedScreens: [String: Set<String>] = [:]
    private(set) var sha256 = ""

    private init(manager: RemoteConfigManager, rootURL: URL) {
        self.manager = manager
        self.rootURL = rootURL
    }

    static func load() async throws -> WorkflowPrewarmingWorkload {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let manager = try PerformanceFixture.makeManager(rootURL: rootURL)
        let workload = WorkflowPrewarmingWorkload(manager: manager, rootURL: rootURL)
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
        XCTAssertFalse(self.offeringIDs.isEmpty, "The fixture needs a mapped workflow.")

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
            await provider.cachePrefetchedWorkflowBodyData(includingOfferingId: identifier)
        }
        let config = await uiConfigProvider.getUiConfig()
        _ = try XCTUnwrap(config)
        return WorkflowPrewarmingIteration(
            manager: WorkflowManager(
                workflowsConfigProvider: provider,
                paywallCache: nil,
                operationDispatcher: .default,
                webBundleURLBatcher: WebBundleURLBatcher(eventBus: WebBundleEventBus())
            ),
            offerings: self.makeOfferings(),
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
    let offerings: Offerings
    let decodedScreens: Atomic<[String: Set<String>]>
    let expectedScreens: [String: Set<String>]

    func run() async {
        await self.manager.publishWebBundleURLs(offerings: self.offerings)
    }

    func validate() {
        XCTAssertEqual(self.decodedScreens.value, self.expectedScreens,
                       "Every workflow and screen must decode in every iteration.")
    }
}
