//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  GenerationGuardedCacheTests.swift
//
//  Created by Rick van der Linden.

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class GenerationGuardedCacheTests: TestCase {

    func testStartsCold() {
        let cache = GenerationGuardedCache<String, String>()

        expect(cache.value(currentGeneration: 0)).to(beNil())
        expect(cache.value(for: .init(generation: 0, key: "key"))).to(beNil())
    }

    func testReturnsStoredValueForMatchingGenerationAndKey() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("value", for: .init(generation: 2, key: "key"))

        expect(cache.value(currentGeneration: 2)) == "value"
        expect(cache.value(for: .init(generation: 2, key: "key"))) == "value"
    }

    func testCurrentGenerationReadClearsOlderValue() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("value", for: .init(generation: 2, key: "key"))

        expect(cache.value(currentGeneration: 3)).to(beNil())
        expect(cache.value(currentGeneration: 2)).to(beNil())
    }

    func testSnapshotReadClearsOlderOrSameGenerationMismatch() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("value", for: .init(generation: 2, key: "old"))

        expect(cache.value(for: .init(generation: 2, key: "new"))).to(beNil())
        expect(cache.value(currentGeneration: 2)).to(beNil())
    }

    func testStaleSnapshotReadDoesNotClearNewerValue() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("new", for: .init(generation: 3, key: "new"))

        expect(cache.value(for: .init(generation: 2, key: "old"))).to(beNil())
        expect(cache.value(currentGeneration: 3)) == "new"
    }

    func testLowerGenerationStoreDoesNotOverwriteNewerValue() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("new", for: .init(generation: 3, key: "key"))
        cache.store("old", for: .init(generation: 2, key: "key"))

        expect(cache.value(currentGeneration: 3)) == "new"
    }

    func testClearIfStaleDoesNotClearSameOrNewerGeneration() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("new", for: .init(generation: 3, key: "key"))

        cache.clearIfStale(currentGeneration: 2)
        expect(cache.value(currentGeneration: 3)) == "new"

        cache.clearIfStale(currentGeneration: 3)
        expect(cache.value(currentGeneration: 3)) == "new"
    }

    func testClearIfStaleClearsOlderGeneration() {
        let cache = GenerationGuardedCache<String, String>()

        cache.store("old", for: .init(generation: 2, key: "key"))

        cache.clearIfStale(currentGeneration: 3)

        expect(cache.value(currentGeneration: 2)).to(beNil())
    }

}
