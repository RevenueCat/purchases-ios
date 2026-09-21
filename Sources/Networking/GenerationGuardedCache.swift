//
//  GenerationGuardedCache.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// Small in-memory cache for remote-config-derived values.
///
/// Values are tagged with the remote config generation and a provider-owned key. Reads only return when
/// the generation is still current, and stale lower-generation stores cannot overwrite newer cache state.
final class GenerationGuardedCache<Key: Equatable, Value> {

    private let lock = Lock()
    private var cached: CachedValue?

    func value(currentGeneration: Int) -> Value? {
        return self.lock.perform {
            guard let cached = self.cached else { return nil }
            guard cached.generation == currentGeneration else {
                if cached.generation < currentGeneration {
                    self.cached = nil
                }
                return nil
            }
            return cached.value
        }
    }

    func value(for snapshot: GenerationGuardedCacheSnapshot<Key>) -> Value? {
        return self.lock.perform {
            guard let cached = self.cached else { return nil }
            guard cached.generation == snapshot.generation,
                  cached.key == snapshot.key else {
                if cached.generation <= snapshot.generation {
                    self.cached = nil
                }
                return nil
            }
            return cached.value
        }
    }

    func store(_ value: Value, for snapshot: GenerationGuardedCacheSnapshot<Key>) {
        self.lock.perform {
            guard snapshot.generation >= (self.cached?.generation ?? Int.min) else { return }
            self.cached = .init(generation: snapshot.generation, key: snapshot.key, value: value)
        }
    }

    func clearIfStale(currentGeneration: Int) {
        self.lock.perform {
            guard let cached = self.cached,
                  cached.generation < currentGeneration else { return }
            self.cached = nil
        }
    }

}

struct GenerationGuardedCacheSnapshot<Key: Equatable> {
    let generation: Int
    let key: Key
}

private extension GenerationGuardedCache {

    struct CachedValue {
        let generation: Int
        let key: Key
        let value: Value
    }

}

extension GenerationGuardedCache: @unchecked Sendable {}
