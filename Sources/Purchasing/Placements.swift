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

@objc(RCPlacements) public final class Placements: NSObject {
    let fallbackOfferingId: String?
    let currentOfferingIdsByPlacement: [String: String]
    
    init(
        fallbackOfferingId: String?,
        currentOfferingIdsByPlacement: [String: String]
    ) {
        self.fallbackOfferingId = fallbackOfferingId
        self.currentOfferingIdsByPlacement = currentOfferingIdsByPlacement
    }
}

extension Placements: Sendable {}
