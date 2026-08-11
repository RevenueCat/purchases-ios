//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeviceDimensionProviderTests.swift
//
//  Created by Rick van der Linden on 8/11/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Device variable provider")
struct DeviceDimensionProviderTests {

    @Test
    func providesDeviceVariablesInDeviceNamespace() async throws {
        let provider = DeviceDimensionProvider(
            appVersion: "1.2.3",
            localeProvider: { "nl_NL" },
            platform: "iOS",
            platformVersion: "Version 26.3 (Build 23D127)",
            sdkVersion: "5.84.0"
        )

        #expect(provider.identifier == "device")
        #expect(provider.namespace == .device)
        #expect(try await provider.dimensions(at: Date()) == [
            "app_version": .string("1.2.3"),
            "locale": .string("nl_NL"),
            "platform": .string("iOS"),
            "platform_version": .string("Version 26.3 (Build 23D127)"),
            "sdk_version": .string("5.84.0")
        ])
    }

    @Test
    func omitsUnavailableValues() async throws {
        let provider = DeviceDimensionProvider(
            appVersion: "",
            localeProvider: { "" },
            platform: "",
            platformVersion: "",
            sdkVersion: ""
        )

        #expect(try await provider.dimensions(at: Date()).isEmpty)
    }

    @Test
    func collectsLocaleForEverySnapshot() async throws {
        let locale = Atomic<String?>("en_US")
        let provider = DeviceDimensionProvider(
            appVersion: "1.2.3",
            localeProvider: { locale.value },
            platform: "iOS",
            platformVersion: "Version 26.3 (Build 23D127)"
        )

        let first = try await provider.dimensions(at: Date())
        locale.value = "nl_NL"
        let second = try await provider.dimensions(at: Date())

        #expect(first["locale"] == .string("en_US"))
        #expect(second["locale"] == .string("nl_NL"))
    }

    @Test
    func appVersionCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en_US" },
                    platform: "iOS",
                    platformVersion: "Version 26.3 (Build 23D127)"
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.app_version"},"1.2.3"]}"#
            )
        ])

        #expect(match == "matching-rule")
    }

    @Test
    func localeCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "nl-NL" },
                    platform: "iOS",
                    platformVersion: "Version 26.3 (Build 23D127)"
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.locale"},"nl-NL"]}"#
            )
        ])

        #expect(match == "matching-rule")
    }

    @Test
    func platformCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en-US" },
                    platform: "iOS",
                    platformVersion: "Version 26.3 (Build 23D127)"
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.platform"},"iOS"]}"#
            )
        ])

        #expect(match == "matching-rule")
    }

    @Test
    func platformVersionCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en-US" },
                    platform: "iOS",
                    platformVersion: "Version 26.3 (Build 23D127)"
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.platform_version"},"Version 26.3 (Build 23D127)"]}"#
            )
        ])

        #expect(match == "matching-rule")
    }

    @Test
    func sdkVersionCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en-US" },
                    platform: "iOS",
                    platformVersion: "Version 26.3 (Build 23D127)",
                    sdkVersion: "5.84.0"
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.sdk_version"},"5.84.0"]}"#
            )
        ])

        #expect(match == "matching-rule")
    }

}

private struct TestRule: LocalRule {

    let id: String
    let predicate: String

}

#endif
#endif
