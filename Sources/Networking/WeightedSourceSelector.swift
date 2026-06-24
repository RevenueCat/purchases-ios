//
//  WeightedSourceSelector.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 24/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// A source the SDK can fetch a resource from (e.g. an API or blob/asset source), carrying the
/// ordering metadata used to choose between alternatives.
///
/// Selection only depends on `id`, `priority` and `weight`; concrete sources add their own
/// connection details (an API `url`, a blob `urlFormat`, etc.) that the selector never inspects.
protocol WeightedSource {

    /// Stable identifier used to exclude an already-tried source from later selections.
    var id: String { get }

    /// Higher values are preferred. The selector always exhausts the highest available priority
    /// tier before considering a lower one.
    var priority: Int { get }

    /// Relative likelihood of being chosen among sources tied at the same `priority`.
    var weight: Int { get }

}

/// Provides the random integers used to break weight ties. Abstracted so tests can make selection
/// deterministic, mirroring the `Random` injection used by the Android SDK.
protocol WeightedSourceRandomizer {

    /// Returns a value in `0..<upperBound`. `upperBound` is always strictly positive.
    func nextInt(upperBound: Int) -> Int

}

struct SystemWeightedSourceRandomizer: WeightedSourceRandomizer {

    func nextInt(upperBound: Int) -> Int {
        return Int.random(in: 0..<upperBound)
    }

}

/// Picks which `Source` to use from a fixed list, and keeps track of the current choice so callers
/// can read it at any time and advance to the next alternative when the current one is unusable.
///
/// Selection rules:
/// - The highest `priority` among the not-yet-tried sources wins.
/// - Ties at that priority are broken by weighted random using `weight`. Negative weights are
///   treated as `0`; if every candidate weighs `0`, the choice is uniform random.
///
/// This type is a pure selection state machine: it does not fetch anything, classify failures, or
/// decide *when* to advance. Those concerns belong to the caller. A single instance models the
/// global selection state for one resource kind (one for API sources, one for blob sources).
///
/// - Note: This type is not thread-safe. Callers that share an instance across concurrent tasks
///   must serialize access to it.
class WeightedSourceSelector<Source: WeightedSource> {

    private let sources: [Source]
    private let randomizer: WeightedSourceRandomizer

    /// Identifiers of sources already returned as `current` during the current selection cycle, and
    /// therefore excluded from future picks until `reset()` is called.
    private var triedIDs: Set<String> = []

    /// The source currently in use, or `nil` if `sources` is empty or every source has been tried.
    /// Reading this never changes the selection.
    private(set) var current: Source?

    init(
        sources: [Source],
        randomizer: WeightedSourceRandomizer = SystemWeightedSourceRandomizer()
    ) {
        self.sources = sources
        self.randomizer = randomizer
        self.current = self.select(excluding: self.triedIDs)
    }

    /// Marks the `current` source as tried and selects the next best alternative, excluding every
    /// source already tried in this cycle.
    ///
    /// - Returns: The newly selected `current`, or `nil` if no untried sources remain.
    @discardableResult
    func advance() -> Source? {
        if let current = self.current {
            self.triedIDs.insert(current.id)
        }
        self.current = self.select(excluding: self.triedIDs)
        return self.current
    }

    /// Clears the tried-source history and re-selects from the full list, returning to the initial
    /// selection behavior. Use when the selection cycle should start over (e.g. the source list
    /// changed, or a previously-failing source should be reconsidered).
    func reset() {
        self.triedIDs.removeAll()
        self.current = self.select(excluding: self.triedIDs)
    }

    private func select(excluding excludedIDs: Set<String>) -> Source? {
        let candidates = self.sources.filter { !excludedIDs.contains($0.id) }
        guard let highestPriority = candidates.map(\.priority).max() else { return nil }

        let topPriority = candidates.filter { $0.priority == highestPriority }
        guard topPriority.count > 1 else { return topPriority.first }

        let weights = topPriority.map { max(0, $0.weight) }
        let totalWeight = weights.reduce(0, +)

        guard totalWeight > 0 else {
            return topPriority[self.randomizer.nextInt(upperBound: topPriority.count)]
        }

        let target = self.randomizer.nextInt(upperBound: totalWeight)
        var cumulative = 0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if target < cumulative {
                return topPriority[index]
            }
        }

        // Unreachable: `target < totalWeight` guarantees a match above. Returns last candidate defensively.
        return topPriority.last
    }

}
