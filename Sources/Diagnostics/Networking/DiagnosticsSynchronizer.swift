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
//  Created by Nacho Soto on 6/16/23.

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
actor DiagnosticsSynchronizer {

    private let api: DiagnosticsAPI
    private let handler: DiagnosticsFileHandlerType

    private var isSyncing = false

    init(
        api: DiagnosticsAPI,
        handler: DiagnosticsFileHandlerType
    ) {
        self.api = api
        self.handler = handler
    }

    func syncDiagnosticsIfNeeded() async {
        guard !self.isSyncing else {
            // TODO: log
            return
        }

        self.isSyncing = true
        defer { self.isSyncing = false }

        let entries = await self.handler.getEntries()
        try? await self.api.postDiagnostics(items: entries)
    }

}

// MARK: - Private

private extension DiagnosticsAPI {

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func postDiagnostics(items: DiagnosticsEntries) async throws {
        return try await Async.call { completion in
            self.postDiagnostics(items: items, completion: completion)
        }
    }

}
