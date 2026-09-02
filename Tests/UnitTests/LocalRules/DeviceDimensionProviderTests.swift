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
    func providesDeviceDimensionsInDeviceNamespace() async throws {
        let provider = DeviceDimensionProvider(
            appVersion: "1.2.3",
            localeProvider: { "NL-nl" },
            platform: "iOS",
            platformVersion: Self.platformVersion,
            sdkVersion: "5.84.0-SNAPSHOT"
        )

        #expect(provider.namespace == .device)
        #expect(try await provider.dimensions(at: Date()) == [
            "appVersion": .string("1.2.3"),
            "locale": .string("nl_nl"),
            "platform": .string("ios"),
            "platformVersion": .string("26.3.0"),
            "sdkVersion": .string("5.84.0")
        ])
    }

    @Test
    func omitsUnavailableOptionalValues() async throws {
        let provider = DeviceDimensionProvider(
            appVersion: "",
            localeProvider: { "" },
            platform: "",
            platformVersion: Self.platformVersion,
            sdkVersion: "invalid"
        )

        #expect(try await provider.dimensions(at: Date()) == [
            "platformVersion": .string("26.3.0")
        ])
    }

    @Test
    func collectsLocaleForEverySnapshot() async throws {
        let locale = Atomic<String?>("en_US")
        let provider = DeviceDimensionProvider(
            appVersion: "1.2.3",
            localeProvider: { locale.value },
            platform: "iOS",
            platformVersion: Self.platformVersion
        )

        let first = try await provider.dimensions(at: Date())
        locale.value = "nl_NL"
        let second = try await provider.dimensions(at: Date())

        #expect(first["locale"] == .string("en_us"))
        #expect(second["locale"] == .string("nl_nl"))
    }

    @Test
    func appVersionCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en_US" },
                    platform: "iOS",
                    platformVersion: Self.platformVersion
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.appVersion"},"1.2.3"]}"#
            )
        ])

        #expect(match?.id == "matching-rule")
    }

    @Test
    func localeCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "nl-NL" },
                    platform: "iOS",
                    platformVersion: Self.platformVersion
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.locale"},"nl_nl"]}"#
            )
        ])

        #expect(match?.id == "matching-rule")
    }

    @Test
    func platformCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en-US" },
                    platform: "iOS",
                    platformVersion: Self.platformVersion
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.platform"},"ios"]}"#
            )
        ])

        #expect(match?.id == "matching-rule")
    }

    @Test
    func platformUsesCompileTargetWhenUniversalAppStoreIsForced() async throws {
        let previousValue = SystemInfo.forceUniversalAppStore
        defer { SystemInfo.forceUniversalAppStore = previousValue }
        SystemInfo.forceUniversalAppStore = true

        let dimensions = try await DeviceDimensionProvider().dimensions(at: Date())

        #expect(dimensions["platform"] == .string(SystemInfo.platformHeaderConstant.lowercased()))
    }

    @Test
    func platformVersionCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en-US" },
                    platform: "iOS",
                    platformVersion: Self.platformVersion
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.platformVersion"},"26.3.0"]}"#
            )
        ])

        #expect(match?.id == "matching-rule")
    }

    @Test
    func sdkVersionCanBeEvaluatedUsingSDKVariablePath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: "1.2.3",
                    localeProvider: { "en-US" },
                    platform: "iOS",
                    platformVersion: Self.platformVersion,
                    sdkVersion: "5.84.0-SNAPSHOT"
                )
            ]
        )

        let match = try await evaluator.match(in: [
            TestRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"device.sdkVersion"},"5.84.0"]}"#
            )
        ])

        #expect(match?.id == "matching-rule")
    }

    private static let platformVersion = OperatingSystemVersion(
        majorVersion: 26,
        minorVersion: 3,
        patchVersion: 0
    )

}

private struct TestRule: LocalRule {

    let id: String
    let predicate: String

}

#endif
#endif
