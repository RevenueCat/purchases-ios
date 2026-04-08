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
        let fetcher = MockWorkflowCdnFetcher { [weak self] url, completion in
            self?.fetchedUrls.append(url)
            completion(.success((try? JSONSerialization.data(withJSONObject: ["id": "from_cdn"])) ?? Data()))
        }
        self.processor = WorkflowDetailProcessor(cdnFetcher: fetcher)
    }

    func testInlineUnwrapsData() throws {
        let envelope: [String: Any] = [
            "action": "inline",
            "data": ["id": "wf_inline"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let parsed = try? JSONSerialization.jsonObject(with: value.workflowData) as? [String: Any]
            expect(parsed?["id"] as? String) == "wf_inline"
            expect(value.enrolledVariants).to(beNil())
        })
    }

    func testInlineExtractsEnrolledVariants() throws {
        let envelope: [String: Any] = [
            "action": "inline",
            "data": ["id": "wf1"],
            "enrolled_variants": ["a": "b"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            expect(value.enrolledVariants) == ["a": "b"]
        })
    }

    func testUseCdnFetchesFromUrl() throws {
        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "enrolled_variants": ["x": "y"]
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(self.fetchedUrls) == ["https://cdn.example/w.json"]
        expect(result).to(beSuccess { value in
            let parsed = try? JSONSerialization.jsonObject(with: value.workflowData) as? [String: Any]
            expect(parsed?["id"] as? String) == "from_cdn"
            expect(value.enrolledVariants) == ["x": "y"]
        })
    }

    func testUnknownActionThrows() throws {
        let envelope: [String: Any] = ["action": "other"]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testUseCdnPropagatesIOErrorAsCdnFetchFailed() throws {
        let failingFetcher = MockWorkflowCdnFetcher { _, completion in
            completion(.failure(URLError(.notConnectedToInternet)))
        }
        let failingProcessor = WorkflowDetailProcessor(cdnFetcher: failingFetcher)

        let envelope: [String: Any] = ["action": "use_cdn", "url": "https://x"]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            failingProcessor.process(data, completion: completed)
        }

        expect(result).to(beFailure { error in
            guard case WorkflowDetailProcessingError.cdnFetchFailed(let underlying) = error else {
                fail("Expected WorkflowDetailProcessingError.cdnFetchFailed, got \(error)")
                return
            }
            expect((underlying as? URLError)?.code) == .notConnectedToInternet
        })
    }

    func testMissingDataInInlineThrows() throws {
        let envelope: [String: Any] = ["action": "inline"]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beFailure())
    }

    func testMissingUrlInUseCdnThrows() throws {
        let envelope: [String: Any] = ["action": "use_cdn"]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beFailure())
    }

}

private final class MockWorkflowCdnFetcher: WorkflowCdnFetcher {

    private let handler: (String, @escaping (Result<Data, Error>) -> Void) -> Void

    init(_ handler: @escaping (String, @escaping (Result<Data, Error>) -> Void) -> Void) {
        self.handler = handler
    }

    func fetchCompiledWorkflowData(cdnUrl: String, completion: @escaping (Result<Data, Error>) -> Void) {
        self.handler(cdnUrl, completion)
    }

}
