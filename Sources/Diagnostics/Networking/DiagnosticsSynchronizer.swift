//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsSynchronizer.swift
//
//  Created by Cesar de la Vega on 8/4/24.

import Foundation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol DiagnosticsSynchronizerType {

    func syncDiagnosticsIfNeeded() async throws

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
actor DiagnosticsSynchronizer: DiagnosticsSynchronizerType {

    private let internalAPI: InternalAPI
    private let handler: DiagnosticsFileHandlerType
    private let userDefaults: SynchronizedUserDefaults

    private var syncInProgress = false

    init(
        internalAPI: InternalAPI,
        handler: DiagnosticsFileHandlerType,
        userDefaults: SynchronizedUserDefaults
    ) {
        self.internalAPI = internalAPI
        self.handler = handler
        self.userDefaults = userDefaults
    }

    func syncDiagnosticsIfNeeded() async throws {
        guard !self.syncInProgress else {
            Logger.debug(Strings.diagnostics.event_sync_already_in_progress)
            return
        }

        self.syncInProgress = true
        defer { self.syncInProgress = false }

        let events = await self.handler.getEntries()
        let count = events.count

        guard !events.isEmpty else {
            Logger.verbose(Strings.diagnostics.event_sync_with_empty_store)
            return
        }

        Logger.verbose(Strings.diagnostics.event_sync_starting(count: count))

        do {
            try await self.internalAPI.postDiagnosticsEvents(events: events)

            await self.handler.cleanSentDiagnostics(diagnosticsSentCount: count)

            self.clearSyncRetries()
        } catch {
            Logger.error(Strings.diagnostics.could_not_synchronize_diagnostics(error: error))

            if let backendError = error as? BackendError,
               backendError.successfullySynced {
                await self.handler.cleanSentDiagnostics(diagnosticsSentCount: count)
                self.clearSyncRetries()
            } else {
                let currentSyncRetries = self.getCurrentSyncRetries()

                if currentSyncRetries >= Self.maxSyncRetries {
                    Logger.error(Strings.diagnostics.failed_diagnostics_sync_more_than_max_retries)
                    await self.handler.emptyDiagnosticsFile()
                    self.clearSyncRetries()
                } else {
                    self.increaseSyncRetries(currentRetries: currentSyncRetries)
                }
            }

            throw error
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsSynchronizer {

    static let maxSyncRetries = 3

    enum CacheKeys: String {
        case numberOfRetries = "com.revenuecat.diagnostics.number_sync_retries"
    }

    func increaseSyncRetries(currentRetries: Int) {
        self.userDefaults.write {
            $0.set(currentRetries + 1, forKey: CacheKeys.numberOfRetries.rawValue)
        }
    }

    func clearSyncRetries() {
        self.userDefaults.write {
            $0.removeObject(forKey: CacheKeys.numberOfRetries.rawValue)
        }
    }

    func getCurrentSyncRetries() -> Int {
        return self.userDefaults.read {
            $0.integer(forKey: CacheKeys.numberOfRetries.rawValue)
        }
    }

}
