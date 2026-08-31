//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomVariableKeyValidatorTests.swift
//
//  Created by Rick van der Linden on 8/12/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Testing

@_spi(Internal) @testable import RevenueCat

@Suite("Custom variable key validation")
struct CustomVariableKeyValidatorTests {

    @Test
    func acceptsAddressableKeys() {
        let validKeys = [
            "validKey",
            "valid_key_name",
            "key123",
            "player_score_2024",
            "a",
            "123key",
            "_key",
            String(repeating: "a", count: 255)
        ]

        #expect(validKeys.allSatisfy { CustomVariableKeyValidator.isValidKey($0) })
    }

    @Test
    func rejectsUnaddressableKeys() {
        let invalidKeys = [
            "",
            "key-name",
            "key name",
            "key.name",
            "key!",
            "kéy",
            String(repeating: "a", count: 256)
        ]

        #expect(invalidKeys.allSatisfy { !CustomVariableKeyValidator.isValidKey($0) })
    }

    @Test
    func invalidKeysAreOmittedFromCustomNamespace() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [],
            currentAppUserIDProvider: { "user" }
        ).snapshot(customVariables: [
            "valid_key": .string("kept"),
            "my.property": .string("dropped"),
            "2fast": .string("also kept"),
            "has space": .string("dropped")
        ])

        #expect(snapshot.values["custom"] == .object([
            "valid_key": .string("kept"),
            "2fast": .string("also kept")
        ]))
    }

    @Test
    func onlyInvalidVariablesLeaveCustomNamespaceAbsent() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [],
            currentAppUserIDProvider: { "user" }
        ).snapshot(customVariables: [
            "invalid.key": .string("dropped")
        ])

        #expect(snapshot.values["custom"] == nil)
    }

}

#endif
#endif
