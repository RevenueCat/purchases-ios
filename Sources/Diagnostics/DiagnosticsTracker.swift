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

protocol DiagnosticsTrackerType: AnyObject {
    
    func track(_ event: DiagnosticsEvent) async

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
final class DiagnosticsTracker {

    private let diagnosticsFileHandler: DiagnosticsFileHandler

    init(diagnosticsFileHandler: DiagnosticsFileHandler) {
        self.diagnosticsFileHandler = diagnosticsFileHandler
    }

    func track(_ event: DiagnosticsEvent) async {
        await diagnosticsFileHandler.appendEvent(diagnosticsEvent: event)
    }
}
