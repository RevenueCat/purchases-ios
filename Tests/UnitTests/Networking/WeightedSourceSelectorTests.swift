//
//  WeightedSourceSelectorTests.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 24/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class WeightedSourceSelectorTests: TestCase {

    // MARK: - Initial selection

    func testCurrentIsNilWhenNoSources() {
        let selector = WeightedSourceSelector<TestSource>(sources: [], randomizer: FakeRandomizer())
        expect(selector.current).to(beNil())
    }

    func testSelectsSingleSource() {
        let only = TestSource(id: "only", priority: 0, weight: 0)
        let selector = WeightedSourceSelector(sources: [only], randomizer: FakeRandomizer(0))
        expect(selector.current) == only
    }

    func testHighestPriorityWins() {
        let low = TestSource(id: "low", priority: 0, weight: 100)
        let high = TestSource(id: "high", priority: 10, weight: 1)
        let selector = WeightedSourceSelector(sources: [low, high], randomizer: FakeRandomizer(0))
        expect(selector.current) == high
    }

    func testHighestPriorityWinsRegardlessOfOrder() {
        let low1 = TestSource(id: "low1", priority: 0, weight: 100)
        let high = TestSource(id: "high", priority: 5, weight: 1)
        let low2 = TestSource(id: "low2", priority: 0, weight: 100)
        let selector = WeightedSourceSelector(sources: [low1, high, low2], randomizer: FakeRandomizer(0))
        expect(selector.current) == high
    }

    // MARK: - Weighted random tie-breaking (weights [30, 70])

    func testWeightedPickLowerBoundaryPicksFirst() {
        let selector = self.weightedPairSelector(target: 0)
        expect(selector.current?.id) == "a"
    }

    func testWeightedPickJustBelowFirstWeightPicksFirst() {
        let selector = self.weightedPairSelector(target: 29)
        expect(selector.current?.id) == "a"
    }

    func testWeightedPickAtFirstWeightPicksSecond() {
        let selector = self.weightedPairSelector(target: 30)
        expect(selector.current?.id) == "b"
    }

    func testWeightedPickUpperBoundaryPicksSecond() {
        let selector = self.weightedPairSelector(target: 99)
        expect(selector.current?.id) == "b"
    }

    // MARK: - Zero / negative weight fallbacks

    func testZeroWeightsUseUniformRandom() {
        let sourceA = TestSource(id: "a", priority: 0, weight: 0)
        let sourceB = TestSource(id: "b", priority: 0, weight: 0)
        expect(WeightedSourceSelector(sources: [sourceA, sourceB], randomizer: FakeRandomizer(0)).current) == sourceA
        expect(WeightedSourceSelector(sources: [sourceA, sourceB], randomizer: FakeRandomizer(1)).current) == sourceB
    }

    func testNegativeWeightsAreClampedToZero() {
        // sourceA has a positive weight, sourceB a negative one. sourceB clamps to 0, so sourceA wins
        // the entire range.
        let sourceA = TestSource(id: "a", priority: 0, weight: 50)
        let sourceB = TestSource(id: "b", priority: 0, weight: -50)
        let selector = WeightedSourceSelector(sources: [sourceA, sourceB], randomizer: FakeRandomizer(0))
        expect(selector.current) == sourceA
    }

    // MARK: - advance()

    func testAdvanceExcludesCurrentAndPicksNextPriorityTier() {
        let high = TestSource(id: "high", priority: 10, weight: 1)
        let low = TestSource(id: "low", priority: 0, weight: 1)
        let selector = WeightedSourceSelector(sources: [high, low], randomizer: FakeRandomizer(0))

        expect(selector.current) == high
        expect(selector.advance()) == low
        expect(selector.current) == low
    }

    func testAdvanceReturnsNilWhenSourcesExhausted() {
        let high = TestSource(id: "high", priority: 10, weight: 1)
        let low = TestSource(id: "low", priority: 0, weight: 1)
        let selector = WeightedSourceSelector(sources: [high, low], randomizer: FakeRandomizer(0))

        expect(selector.advance()) == low
        expect(selector.advance()).to(beNil())
        expect(selector.current).to(beNil())
    }

    func testAdvanceWalksTiedSourcesByWeightExcludingTried() {
        // sourceA(30) is drawn first via target 0; the rest of the tier is precomputed, so advancing
        // walks to the only remaining source (b) without consuming more randomness.
        let sourceA = TestSource(id: "a", priority: 0, weight: 30)
        let sourceB = TestSource(id: "b", priority: 0, weight: 70)
        let selector = WeightedSourceSelector(sources: [sourceA, sourceB], randomizer: FakeRandomizer(0))

        expect(selector.current?.id) == "a"
        expect(selector.advance()?.id) == "b"
        expect(selector.advance()).to(beNil())
    }

    func testAdvanceWalksFullWeightedOrderWithinTier() {
        // Three tied sources. The eager order is built by drawing without replacement: target 70
        // skips a(30) and lands on b, then among the remaining [a, c] target 0 picks a, leaving c.
        let sourceA = TestSource(id: "a", priority: 0, weight: 30)
        let sourceB = TestSource(id: "b", priority: 0, weight: 70)
        let sourceC = TestSource(id: "c", priority: 0, weight: 50)
        let selector = WeightedSourceSelector(
            sources: [sourceA, sourceB, sourceC],
            randomizer: FakeRandomizer(70, 0)
        )

        expect(selector.current?.id) == "b"
        expect(selector.advance()?.id) == "a"
        expect(selector.advance()?.id) == "c"
        expect(selector.advance()).to(beNil())
    }

    // MARK: - reset()

    func testResetClearsTriedHistoryAndReselects() {
        let high = TestSource(id: "high", priority: 10, weight: 1)
        let low = TestSource(id: "low", priority: 0, weight: 1)
        let selector = WeightedSourceSelector(sources: [high, low], randomizer: FakeRandomizer(0))

        expect(selector.advance()) == low
        selector.reset()
        expect(selector.current) == high
        expect(selector.advance()) == low
    }

    // MARK: - Helpers

    private func weightedPairSelector(target: Int) -> WeightedSourceSelector<TestSource> {
        let sourceA = TestSource(id: "a", priority: 0, weight: 30)
        let sourceB = TestSource(id: "b", priority: 0, weight: 70)
        return WeightedSourceSelector(sources: [sourceA, sourceB], randomizer: FakeRandomizer(target))
    }

}

private struct TestSource: WeightedSource, Equatable {

    let id: String
    let priority: Int
    let weight: Int

}

/// Returns queued values from `randomInt(below:)`, clamped into range, repeating the last value
/// once the queue is drained. Mirrors the Android `FakeRandom`/`QueuedRandom` test helpers.
private final class FakeRandomizer: WeightedSourceRandomizer {

    private var values: [Int]
    private var index = 0

    init(_ values: Int...) {
        self.values = values.isEmpty ? [0] : values
    }

    func randomInt(below bound: Int) -> Int {
        let value = self.index < self.values.count ? self.values[self.index] : self.values.last!
        self.index += 1
        return min(max(0, value), bound - 1)
    }

}
