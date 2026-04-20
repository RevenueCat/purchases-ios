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
        self.processor = WorkflowDetailProcessor(cdnFetch: { [weak self] url, _, completion in
            self?.fetchedUrls.append(url)
            completion(.success((try? JSONSerialization.data(withJSONObject: ["id": "from_cdn"])) ?? Data()))
        })
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

    func testUseCdnPassesThroughCdnHashMismatchFromFetch() throws {
        let processor = WorkflowDetailProcessor(cdnFetch: { _, _, completion in
            completion(.failure(WorkflowDetailProcessingError.cdnHashMismatch))
        }, responseVerificationMode: .disabled)

        let envelope: [String: Any] = ["action": "use_cdn", "url": "https://x", "hash": "abc"]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            processor.process(data, completion: completed)
        }

        expect(result).to(beFailure { error in
            guard case WorkflowDetailProcessingError.cdnHashMismatch = error else {
                fail("Expected cdnHashMismatch, got \(error)")
                return
            }
        })
    }

    func testUseCdnPropagatesIOErrorAsCdnFetchFailed() throws {
        let failingProcessor = WorkflowDetailProcessor(cdnFetch: { _, _, completion in
            completion(.failure(URLError(.notConnectedToInternet)))
        }, responseVerificationMode: .disabled)

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

    // MARK: - CDN hash verification

    func testUseCdnSucceedsWithValidHash() throws {
        let cdnData = try JSONSerialization.data(withJSONObject: ["id": "from_cdn"])
        let expectedHash = cdnData.sha256String

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": expectedHash
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let parsed = try? JSONSerialization.jsonObject(with: value.workflowData) as? [String: Any]
            expect(parsed?["id"] as? String) == "from_cdn"
        })
    }

    func testUseCdnFailsWithInvalidHash() throws {
        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": "0000000000000000000000000000000000000000000000000000000000000000"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beFailure { error in
            guard case WorkflowDetailProcessingError.cdnHashMismatch = error else {
                fail("Expected cdnHashMismatch, got \(error)")
                return
            }
        })
    }

    func testUseCdnSucceedsWhenHashMissing() throws {
        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess())
    }

    // MARK: - verifyCdnHash (unit tests for the static method)

    func testVerifyCdnHashReturnsTrueForMatchingHash() throws {
        let contentData = try JSONSerialization.data(withJSONObject: ["id": "wf_abc", "steps": ["a": 1]])
        let hash = contentData.sha256String

        expect(WorkflowDetailProcessor.verifyCdnHash(contentData, expectedHash: hash)) == true
    }

    func testVerifyCdnHashReturnsFalseForMismatch() throws {
        let contentData = try JSONSerialization.data(withJSONObject: ["id": "wf_abc"])

        expect(WorkflowDetailProcessor.verifyCdnHash(contentData, expectedHash: "wrong")) == false
    }

    func testVerifyCdnHashReturnsFalseForInvalidData() {
        let invalidData = Data("not json".utf8)
        expect(WorkflowDetailProcessor.verifyCdnHash(invalidData, expectedHash: "anything")) == false
    }

}

