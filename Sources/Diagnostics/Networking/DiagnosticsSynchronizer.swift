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

    private var flushInProgress = false

    init(
        internalAPI: InternalAPI,
        handler: DiagnosticsFileHandlerType
    ) {
        self.internalAPI = internalAPI
        self.handler = handler
    }

    func syncDiagnosticsIfNeeded() async throws {
        guard !self.flushInProgress else {
            Logger.debug(Strings.diagnostics.event_flush_already_in_progress)
            return
        }

        self.flushInProgress = true
        defer { self.flushInProgress = false }

        let events = await self.handler.getEntries()
        let count = events.count

        guard !events.isEmpty else {
            Logger.verbose(Strings.diagnostics.event_flush_with_empty_store)
            return
        }

        Logger.verbose(Strings.diagnostics.event_flush_starting(count: count))

        do {
            try await self.internalAPI.postDiagnosticsEvents(events: events)

            await self.handler.cleanSentDiagnostics(diagnosticsSentCount: count)
        } catch {
            Logger.error(Strings.paywalls.event_flush_failed(error))

            if let backendError = error as? BackendError,
               backendError.successfullySynced {
                await self.handler.cleanSentDiagnostics(diagnosticsSentCount: count)
            }

            throw error
        }
    }

}
