//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsAPI.swift
//
//  Created by Cesar de la Vega on 8/4/24.

import Foundation

final class DiagnosticsAPI: Sendable {

    typealias ResponseHandler = Backend.ResponseHandler<Void>

    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
    }

    func postDiagnostics(
        items: DiagnosticsEntries,
        completion: @escaping DiagnosticsAPI.ResponseHandler
    ) {
        self.backendConfig.addDiagnosticsOperation(
            DiagnosticsPostOperation(
                configuration: self.backendConfig,
                entries: items,
                responseHandler: completion
            ),
            delay: .long
        )
    }

}
