//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HealthReportAvailabilityResponse.swift
//
//  Created by Pol Piella Abadia on 27/06/2025.

import Foundation

struct HealthReportAvailability {
    let reportLogs: Bool
}

extension HealthReportAvailability: HTTPResponseBody {}
extension HealthReportAvailability: Codable, Equatable {}
