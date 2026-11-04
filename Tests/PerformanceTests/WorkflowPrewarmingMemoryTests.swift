//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowPrewarmingMemoryTests.swift
//

import CryptoKit
import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

// swiftlint:disable:next xctestcase_superclass
final class WorkflowPrewarmingMemoryTests: XCTestCase {

    private var manager: RemoteConfigManager!
    private var rootURL: URL!
    private var offeringIDs: [String] = []
    private var workflowIDs: Set<String> = []

    override func setUp() async throws {
        try await super.setUp()
        let apiKey = try XCTUnwrap(
            ProcessInfo.processInfo.environment["REVENUECAT_PERFORMANCE_API_KEY"],
            "Set REVENUECAT_PERFORMANCE_API_KEY to the benchmark project's SDK key."
        )
        Purchases.logLevel = .error
        self.rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        self.manager = try PerformanceBackend.makeManager(apiKey: apiKey, rootURL: self.rootURL)
        let workflows = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows)
        let topic = try XCTUnwrap(workflows)
        self.offeringIDs = Set(topic.values.compactMap { item in
            guard case let .string(identifier)? = item.content["offering_identifier"] else { return nil }
            return identifier
        }).sorted()
        XCTAssertGreaterThan(self.offeringIDs.count, 1, "The benchmark needs multiple mapped workflows.")

        let provider = WorkflowsConfigProvider(manager: self.manager)
        var fingerprint = SHA256()
        var byteCount = 0
        for offeringID in self.offeringIDs {
            let mappedID = await provider.workflowId(forOfferingId: offeringID)
            let workflowID = try XCTUnwrap(mappedID)
            self.workflowIDs.insert(workflowID)
            let body = await self.manager.blobData(for: .workflows, itemKey: workflowID)
            let data = try XCTUnwrap(body)
            fingerprint.update(data: Data(offeringID.utf8))
            fingerprint.update(data: data)
            byteCount += data.count
        }
        let uiTopic = await self.manager.awaitTopicAndPrefetchBlobsReady(.uiConfig)
        for key in try XCTUnwrap(uiTopic).keys.sorted() {
            let body = await self.manager.blobData(for: .uiConfig, itemKey: key)
            fingerprint.update(data: try XCTUnwrap(body))
        }
        let digest = fingerprint.finalize().map { String(format: "%02x", $0) }.joined()
        print("PERFORMANCE_WORKLOAD sha256=\(digest) workflows=\(self.workflowIDs.count) bytes=\(byteCount)")
    }

    override func tearDownWithError() throws {
        self.manager?.close()
        self.manager = nil
        if let rootURL = self.rootURL {
            try FileManager.default.removeItem(at: rootURL)
        }
        try super.tearDownWithError()
    }

    func testPublishWebBundleURLsPeakMemory() {
        let offerings = self.makeOfferings()
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]

        self.measure(metrics: [XCTMemoryMetric(), XCTClockMetric()], options: options) {
            let decodedIDs = Atomic<Set<String>>([])
            let uiConfigProvider = UiConfigProvider(manager: self.manager)
            let provider = WorkflowsConfigProvider(
                manager: self.manager,
                uiConfigProvider: uiConfigProvider,
                workflowDecoder: { data in
                    let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
                    decodedIDs.modify { $0.insert(workflow.id) }
                    return workflow
                }
            )
            let workflowManager = WorkflowManager(
                workflowsConfigProvider: provider,
                paywallCache: nil,
                operationDispatcher: .default,
                webBundleURLBatcher: WebBundleURLBatcher(eventBus: WebBundleEventBus())
            )
            self.waitForCompletion {
                for identifier in self.offeringIDs {
                    await provider.cachePrefetchedWorkflowBodyData(includingOfferingId: identifier)
                }
                let config = await uiConfigProvider.getUiConfig()
                XCTAssertNotNil(config)
            }

            self.startMeasuring()
            self.waitForCompletion {
                await workflowManager.publishWebBundleURLs(offerings: offerings)
            }
            self.stopMeasuring()

            XCTAssertEqual(decodedIDs.value, self.workflowIDs, "Every workflow must decode in every iteration.")
        }
    }

    private func waitForCompletion(_ operation: @escaping () async -> Void) {
        let completed = self.expectation(description: "Workflow operation completed")
        Task {
            await operation()
            completed.fulfill()
        }
        self.wait(for: [completed], timeout: 120)
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
