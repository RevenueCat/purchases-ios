//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowDetailProcessorTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class WorkflowDetailProcessorTests: TestCase {

    private var processor: WorkflowDetailProcessor!
    private var fetchedUrls: [String] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.fetchedUrls = []
        let fetcher = MockWorkflowCdnFetcher { [weak self] url in
            self?.fetchedUrls.append(url)
            return try JSONSerialization.data(withJSONObject: ["id": "from_cdn"])
        }
        self.processor = WorkflowDetailProcessor(cdnFetcher: fetcher)
    }

    func testInlineUnwrapsData() throws {
        let envelope: [String: Any] = [
            "action": "inline",
            "data": ["id": "wf_inline"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = try processor.process(data)

        let parsed = try JSONSerialization.jsonObject(with: result.workflowData) as? [String: Any]
        expect(parsed?["id"] as? String) == "wf_inline"
        expect(result.enrolledVariants).to(beNil())
    }

    func testInlineExtractsEnrolledVariants() throws {
        let envelope: [String: Any] = [
            "action": "inline",
            "data": ["id": "wf1"],
            "enrolled_variants": ["a": "b"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = try processor.process(data)

        expect(result.enrolledVariants) == ["a": "b"]
    }

    func testUseCdnFetchesFromUrl() throws {
        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "enrolled_variants": ["x": "y"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = try processor.process(data)

        expect(self.fetchedUrls) == ["https://cdn.example/w.json"]
        let parsed = try JSONSerialization.jsonObject(with: result.workflowData) as? [String: Any]
        expect(parsed?["id"] as? String) == "from_cdn"
        expect(result.enrolledVariants) == ["x": "y"]
    }

    func testUnknownActionThrows() throws {
        let envelope: [String: Any] = [
            "action": "other"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        expect(try self.processor.process(data)).to(throwError())
    }

    func testUseCdnPropagatesIOError() throws {
        let failingFetcher = MockWorkflowCdnFetcher { _ in
            throw URLError(.notConnectedToInternet)
        }
        let failingProcessor = WorkflowDetailProcessor(cdnFetcher: failingFetcher)

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://x"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        expect(try failingProcessor.process(data)).to(throwError())
    }

    func testMissingDataInInlineThrows() throws {
        let envelope: [String: Any] = [
            "action": "inline"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        expect(try self.processor.process(data)).to(throwError())
    }

    func testMissingUrlInUseCdnThrows() throws {
        let envelope: [String: Any] = [
            "action": "use_cdn"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        expect(try self.processor.process(data)).to(throwError())
    }

}

private final class MockWorkflowCdnFetcher: WorkflowCdnFetcher {

    private let handler: (String) throws -> Data

    init(_ handler: @escaping (String) throws -> Data) {
        self.handler = handler
    }

    func fetchCompiledWorkflowData(cdnUrl: String) throws -> Data {
        return try handler(cdnUrl)
    }

}
