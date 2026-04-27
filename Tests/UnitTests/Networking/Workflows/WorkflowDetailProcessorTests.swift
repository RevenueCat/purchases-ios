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

@_spi(Internal) @testable import RevenueCat

class WorkflowDetailProcessorTests: TestCase {

    private var processor: WorkflowDetailProcessor!
    private var fetchedUrls: [String] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.fetchedUrls = []
        self.processor = WorkflowDetailProcessor(cdnFetch: { [weak self] url, _, completion in
            self?.fetchedUrls.append(url)
            completion(.success(Self.minimalWorkflowData(id: "from_cdn")))
        })
    }

    func testInlineUnwrapsData() throws {
        let envelope: [String: Any] = [
            "action": "inline",
            "data": Self.minimalWorkflowDict(id: "wf_inline")
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            expect(value.workflow.id) == "wf_inline"
            expect(value.enrolledVariants).to(beNil())
        })
    }

    func testInlineExtractsEnrolledVariants() throws {
        let envelope: [String: Any] = [
            "action": "inline",
            "data": Self.minimalWorkflowDict(id: "wf1"),
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

    func testStepDictionaryKeysMatchInitialStepId() throws {
        // "step_1" in steps must survive decoding unchanged so workflow.steps[workflow.initialStepId]
        // returns a non-nil step. Guards against any future decoder change that would alter
        // dictionary keys and break workflow navigation.
        let envelope: [String: Any] = [
            "action": "inline",
            "data": Self.minimalWorkflowDict(id: "wf1")
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let workflow = value.workflow
            expect(workflow.steps[workflow.initialStepId]).notTo(beNil())
        })
    }

    func testStepDictionaryKeysPreserveCamelCase() throws {
        // camelCase keys like "stepTwo" must also survive decoding unchanged.
        let jsonString = """
        {
            "action": "inline",
            "data": {
                "id": "wf1",
                "display_name": "Test",
                "initial_step_id": "stepTwo",
                "steps": {
                    "stepTwo": {
                        "id": "stepTwo",
                        "type": "screen"
                    }
                },
                "screens": {},
                "ui_config": {
                    "app": {"colors": {}, "fonts": {}},
                    "localizations": {},
                    "variable_config": {
                        "variable_compatibility_map": {},
                        "function_compatibility_map": {}
                    }
                }
            }
        }
        """
        let data = Data(jsonString.utf8)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let workflow = value.workflow
            expect(workflow.initialStepId) == "stepTwo"
            expect(workflow.steps[workflow.initialStepId]).notTo(beNil())
        })
    }

    func testTriggerActionDictionaryKeysMatchActionId() throws {
        // "btn_wagcLsIVjN" in trigger_actions must survive decoding unchanged so that
        // step.triggerActions[trigger.actionId] returns the action. Guards against any future
        // decoder change that would alter dictionary keys.
        let jsonString = """
        {
            "action": "inline",
            "data": {
                "id": "wf1",
                "display_name": "Test",
                "initial_step_id": "step_1",
                "steps": {
                    "step_1": {
                        "id": "step_1",
                        "type": "screen",
                        "trigger_actions": {
                            "btn_wagcLsIVjN": {
                                "type": "navigate",
                                "step_id": "step_2"
                            }
                        }
                    }
                },
                "screens": {},
                "ui_config": {
                    "app": {"colors": {}, "fonts": {}},
                    "localizations": {},
                    "variable_config": {
                        "variable_compatibility_map": {},
                        "function_compatibility_map": {}
                    }
                }
            }
        }
        """
        let data = Data(jsonString.utf8)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let step = value.workflow.steps["step_1"]
            expect(step).notTo(beNil())
            let action = step?.triggerActions["btn_wagcLsIVjN"]
            expect(action) == .step(stepId: "step_2")
        })
    }

    func testInlinePreservesFloatNumericPrecision() throws {
        // Whole-number floats like 1.0 are decoded as .int by AnyDecodable (Foundation
        // allows decoding 1.0 as Int); use fractional values to exercise the .double path.
        let jsonString = """
        {
            "action": "inline",
            "data": {
                "id": "wf_floats",
                "display_name": "Float Test",
                "initial_step_id": "step_1",
                "steps": {
                    "step_1": {
                        "id": "step_1",
                        "type": "screen",
                        "param_values": {"one_point_o": 1.5, "tiny": 1e-06}
                    }
                },
                "screens": {},
                "ui_config": {
                    "app": {"colors": {}, "fonts": {}},
                    "localizations": {},
                    "variable_config": {
                        "variable_compatibility_map": {},
                        "function_compatibility_map": {}
                    }
                }
            }
        }
        """
        let data = Data(jsonString.utf8)

        let result = waitUntilValue { completed in
            self.processor.process(data, completion: completed)
        }

        expect(result).to(beSuccess { value in
            let step = value.workflow.steps["step_1"]
            if case .double(let doubleValue) = step?.paramValues["one_point_o"] {
                expect(doubleValue) == 1.5
            } else {
                fail("Expected .double(1.5), got \(String(describing: step?.paramValues["one_point_o"]))")
            }
            if case .double(let doubleValue) = step?.paramValues["tiny"] {
                expect(doubleValue).to(beCloseTo(1e-06, within: 1e-20))
            } else {
                fail("Expected .double for tiny, got \(String(describing: step?.paramValues["tiny"]))")
            }
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
            expect(value.workflow.id) == "from_cdn"
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
        })

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
        })

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
        let cdnData = Self.minimalWorkflowData(id: "wf_cdn")
        let expectedHash = cdnData.sha256String

        let processor = WorkflowDetailProcessor(cdnFetch: { _, _, completion in
            completion(.success(cdnData))
        })

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
            expect(value.workflow.id) == "wf_cdn"
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

// MARK: - Fixtures

private extension WorkflowDetailProcessorTests {

    static let minimalUiConfig: [String: Any] = [
        "app": [
            "colors": [:] as [String: Any],
            "fonts": [:] as [String: Any]
        ] as [String: Any],
        "localizations": [:] as [String: Any],
        "variable_config": [
            "variable_compatibility_map": [:] as [String: String],
            "function_compatibility_map": [:] as [String: String]
        ] as [String: Any]
    ]

    static func minimalWorkflowDict(id: String) -> [String: Any] {
        return [
            "id": id,
            "display_name": "Test Workflow",
            "initial_step_id": "step_1",
            "steps": [
                "step_1": [
                    "id": "step_1",
                    "type": "screen"
                ] as [String: Any]
            ] as [String: Any],
            "screens": [:] as [String: Any],
            "ui_config": minimalUiConfig
        ]
    }

    static func minimalWorkflowData(id: String) -> Data {
        return (try? JSONSerialization.data(withJSONObject: minimalWorkflowDict(id: id))) ?? Data()
    }

}
