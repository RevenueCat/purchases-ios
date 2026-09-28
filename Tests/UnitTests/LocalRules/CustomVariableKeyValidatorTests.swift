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
            "kéy",
            "π_3",
            "١valid",
            String(repeating: "a", count: 256),
            String(repeating: "a", count: 1_024)
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
            "key🙂",
            "e\u{301}"
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

    @Test
    func newlyAcceptedKeysAreAvailableInCustomNamespace() async throws {
        let longKey = String(repeating: "a", count: 1_024)
        let snapshot = try await DimensionResolver(
            dimensionProviders: [],
            currentAppUserIDProvider: { "user" }
        ).snapshot(customVariables: [
            "kéy": .string("unicode"),
            "١valid": .string("digit"),
            longKey: .string("long")
        ])

        guard case let .object(custom)? = snapshot.values["custom"] else {
            Issue.record("Expected custom variables to be present")
            return
        }
        #expect(custom["kéy"] == .string("unicode"))
        #expect(custom["١valid"] == .string("digit"))
        #expect(custom[longKey] == .string("long"))
    }

    @Test
    func invalidKeysAreLoggedWhenFiltered() {
        let logger = TestLogHandler(testIdentifier: #function)

        _ = CustomVariableKeyValidator.validateAndFilter([
            "invalid.key": "dropped"
        ])

        logger.verifyMessageWasLogged(
            "Custom variable key 'invalid.key' is invalid and will be ignored. " +
                "Keys must not be empty and contain only letters, numbers, and underscores.",
            level: .warn
        )
    }

}

#endif
#endif
