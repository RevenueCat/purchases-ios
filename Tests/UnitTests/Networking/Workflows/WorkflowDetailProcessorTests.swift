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
        }, responseVerificationMode: .disabled)
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

    // MARK: - CDN hash verification (disabled mode)

    func testUseCdnSkipsHashCheckWhenVerificationDisabled() throws {
        // Verification disabled: hash mismatch should be ignored
        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": "0000000000000000000000000000000000000000000000000000000000000000"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess())
    }

    // MARK: - CDN hash verification (informational mode)

    func testUseCdnSucceedsWithValidHashInInformationalMode() throws {
        let processor = self.processorWithVerification(mode: .informational(Signing.loadPublicKey()))

        // SHA-256 of '{"id":"from_cdn"}' (sorted keys, compact separators)
        let expectedHash = "b9c022b65b0163693e3a4feb85299a46a31d46b5c408c15a70537190af8652a8"

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": expectedHash
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let parsed = try? JSONSerialization.jsonObject(with: value.workflowData) as? [String: Any]
            expect(parsed?["id"] as? String) == "from_cdn"
        })
    }

    func testUseCdnSucceedsWithInvalidHashInInformationalMode() throws {
        // Informational mode: hash mismatch logs a warning but does not fail
        let processor = self.processorWithVerification(mode: .informational(Signing.loadPublicKey()))

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": "0000000000000000000000000000000000000000000000000000000000000000"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess())
    }

    func testUseCdnSucceedsWithMissingHashInInformationalMode() throws {
        // Informational mode: missing hash logs a warning but does not fail
        let processor = self.processorWithVerification(mode: .informational(Signing.loadPublicKey()))

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess())
    }

    // MARK: - CDN hash verification (enforced mode)

    func testUseCdnSucceedsWithValidHashInEnforcedMode() throws {
        let cdnData = try JSONSerialization.data(withJSONObject: ["id": "from_cdn"])
        let expectedHash = cdnData.sha256String
        let processor = self.processorWithVerification(mode: .enforced(Signing.loadPublicKey()))

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": expectedHash
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess())
    }

    func testUseCdnFailsWithInvalidHashInEnforcedMode() throws {
        let processor = self.processorWithVerification(mode: .enforced(Signing.loadPublicKey()))

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json",
            "hash": "0000000000000000000000000000000000000000000000000000000000000000"
        ]
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

    func testUseCdnFailsWithMissingHashInEnforcedMode() throws {
        let processor = self.processorWithVerification(mode: .enforced(Signing.loadPublicKey()))

        let envelope: [String: Any] = [
            "action": "use_cdn",
            "url": "https://cdn.example/w.json"
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            processor.process(data, completion: completed)
        }

        expect(result).to(beFailure { error in
            guard case WorkflowDetailProcessingError.missingCdnHash = error else {
                fail("Expected missingCdnHash, got \(error)")
                return
            }
        })
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

// MARK: - Helpers

private extension WorkflowDetailProcessorTests {

    func processorWithVerification(
        mode: Signing.ResponseVerificationMode
    ) -> WorkflowDetailProcessor {
        return WorkflowDetailProcessor(cdnFetch: { [weak self] url, _, completion in
            self?.fetchedUrls.append(url)
            completion(.success(
                (try? JSONSerialization.data(withJSONObject: ["id": "from_cdn"])) ?? Data()
            ))
        }, responseVerificationMode: mode)
    }

}
