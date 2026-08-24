//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreDimensionProviderTests.swift
//
//  Created by Rick van der Linden on 8/12/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Store dimension provider")
struct StoreDimensionProviderTests {

    @Test
    func providesStoreCountryInStoreNamespace() async throws {
        let provider = StoreDimensionProvider(storefrontCountryCodeProvider: { "USA" })

        #expect(provider.namespace == .store)
        #expect(try await provider.dimensions(at: Date()) == [
            "country": .string("USA")
        ])
    }

    @Test
    func omitsUnavailableOrEmptyStoreCountry() async throws {
        let unavailableProvider = StoreDimensionProvider(storefrontCountryCodeProvider: { nil })
        let emptyProvider = StoreDimensionProvider(storefrontCountryCodeProvider: { "" })

        #expect(try await unavailableProvider.dimensions(at: Date()).isEmpty)
        #expect(try await emptyProvider.dimensions(at: Date()).isEmpty)
    }

    @Test
    func collectsStoreCountryForEverySnapshot() async throws {
        let storefrontCountryCode = Atomic<String?>("USA")
        let provider = StoreDimensionProvider(
            storefrontCountryCodeProvider: { storefrontCountryCode.value }
        )

        let first = try await provider.dimensions(at: Date())
        storefrontCountryCode.value = "NLD"
        let second = try await provider.dimensions(at: Date())

        #expect(first["country"] == .string("USA"))
        #expect(second["country"] == .string("NLD"))
    }

    @Test
    func countryCanBeEvaluatedUsingSDKDimensionPath() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                StoreDimensionProvider(storefrontCountryCodeProvider: { "NLD" })
            ]
        )

        let match = try await evaluator.match(in: [
            TestStoreRule(
                predicate: #"{"==":[{"var":"store.country"},"NLD"]}"#
            )
        ])

        #expect(match != nil)
    }

}

private struct TestStoreRule: LocalRule {

    let predicate: String

}

#endif
#endif
