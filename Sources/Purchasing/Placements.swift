//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Placements.swift
//
//  Created by Guido Torres on 15/02/2024.

import Foundation

internal final class Placements: NSObject {
    let fallbackOfferingId: String?
    let offeringIdsByPlacement: [String: String?]

    init(
        fallbackOfferingId: String?,
        offeringIdsByPlacement: [String: String?]
    ) {
        self.fallbackOfferingId = fallbackOfferingId
        self.offeringIdsByPlacement = offeringIdsByPlacement
    }
}

extension Placements: Sendable {}
