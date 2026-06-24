//
//  WeightedSourceSelector.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 24/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// A source the SDK can fetch a resource from, carrying the metadata used to choose between
/// alternatives.
protocol WeightedSource {

    /// Higher values are preferred. A tier is exhausted before a lower one is considered.
    var priority: Int { get }

    /// Relative likelihood of being chosen among sources tied at the same `priority`.
    var weight: Int { get }

}

/// Provides the random integers used to break weight ties. Abstracted so tests can be deterministic.
protocol WeightedSourceRandomizer {

    /// Returns a fresh random value in `0..<bound`. `bound` is always strictly positive.
    func randomInt(below bound: Int) -> Int

}

struct SystemWeightedSourceRandomizer: WeightedSourceRandomizer {

    func randomInt(below bound: Int) -> Int {
        return Int.random(in: 0..<bound)
    }

}

/// Picks which `Source` to use and exposes `current` so callers can advance through the fallback
/// order when a source is unusable.
///
/// The order is computed up front: priority tiers from highest to lowest, each tier arranged into a
/// weight-biased random order. Negative weights are treated as `0`; when a group's weights sum to
/// `0`, the next source is drawn uniformly at random.
///
/// - Note: Not thread-safe. Callers sharing an instance must serialize access.
class WeightedSourceSelector<Source: WeightedSource> {

    private let orderedSources: [Source]
    private var iterator: IndexingIterator<[Source]>

    /// The source currently in use, or `nil` if there are no sources left to try.
    private(set) var current: Source?

    init(
        sources: [Source],
        randomizer: WeightedSourceRandomizer = SystemWeightedSourceRandomizer()
    ) {
        self.orderedSources = Self.computeOrder(of: sources, randomizer: randomizer)
        self.iterator = self.orderedSources.makeIterator()
        self.current = self.iterator.next()
    }

    /// Moves to the next source in the fallback order. Returns `nil` if none remain.
    @discardableResult
    func advance() -> Source? {
        self.current = self.iterator.next()
        return self.current
    }

    /// Rewinds to the first source in the fallback order.
    func reset() {
        self.iterator = self.orderedSources.makeIterator()
        self.current = self.iterator.next()
    }

    private static func computeOrder(
        of sources: [Source],
        randomizer: WeightedSourceRandomizer
    ) -> [Source] {
        let sourcesByPriority = Dictionary(grouping: sources, by: { $0.priority })
        return sourcesByPriority.keys
            .sorted(by: >)
            .flatMap { weightedShuffle(sourcesByPriority[$0] ?? [], randomizer: randomizer) }
    }

    private static func weightedShuffle(
        _ tier: [Source],
        randomizer: WeightedSourceRandomizer
    ) -> [Source] {
        guard tier.count > 1 else { return tier }

        var remaining = tier
        var ordered: [Source] = []
        ordered.reserveCapacity(remaining.count)
        while remaining.count > 1 {
            ordered.append(remaining.remove(at: weightedPickIndex(in: remaining, randomizer: randomizer)))
        }
        ordered.append(contentsOf: remaining)
        return ordered
    }

    private static func weightedPickIndex(
        in sources: [Source],
        randomizer: WeightedSourceRandomizer
    ) -> Int {
        let weights = sources.map { max(0, $0.weight) }
        let totalWeight = weights.reduce(0, +)

        guard totalWeight > 0 else {
            return randomizer.randomInt(below: sources.count)
        }

        let target = randomizer.randomInt(below: totalWeight)
        var cumulative = 0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if target < cumulative {
                return index
            }
        }

        return sources.count - 1
    }

}
