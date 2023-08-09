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
//  Created by Nacho Soto on 6/16/23.

import Foundation

class DiagnosticsAPI {

    typealias ResponseHandler = Backend.ResponseHandler<Void>

    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
    }

    func postDiagnostics(
        items: DiagnosticsEntries,
        completion: @escaping DiagnosticsAPI.ResponseHandler
    ) {
        self.backendConfig.addOperation(
            DiagnosticsPostOperation(
                configuration: self.backendConfig,
                responseHandler: completion
            ),
            withRandomDelay: true
        )
    }

}
