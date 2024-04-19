//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsTracker.swift
//
//  Created by Cesar de la Vega on 4/4/24.

import Foundation

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
protocol DiagnosticsTrackerType: Sendable {

    func track(_ event: DiagnosticsEvent) async

    func trackMaxEventsStoredLimitReached() async

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class DiagnosticsTracker: DiagnosticsTrackerType {

    private let diagnosticsFileHandler: DiagnosticsFileHandler
    private let dateProvider: DateProvider

    init(diagnosticsFileHandler: DiagnosticsFileHandler,
         dateProvider: DateProvider = .init()) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
        self.dateProvider = dateProvider
    }

    func track(_ event: DiagnosticsEvent) async {
        await diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
    }

    func trackMaxEventsStoredLimitReached() async {
        await self.track(.init(eventType: .maxEventsStoredLimitReached,
                               properties: [:],
                               timestamp: self.dateProvider.now()))
    }
}
