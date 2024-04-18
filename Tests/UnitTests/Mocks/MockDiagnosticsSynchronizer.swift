//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockDiagnosticsSynchronizer.swift
//
//  Created by Cesar de la Vega on 18/4/24.

import Foundation
@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class MockDiagnosticsSynchronizer: DiagnosticsSynchronizerType {

    private(set) var invokedSyncDiagnosticsIfNeeded = false

    func syncDiagnosticsIfNeeded() async throws {
        invokedSyncDiagnosticsIfNeeded = true
    }

}
