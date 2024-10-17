//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEvent.swift
//
//  Created by Cesar de la Vega on 15/10/24.

import Foundation

public protocol FeatureEvent: Equatable, Codable, Sendable {

    /// An identifier that represents an event.
    typealias ID = UUID

    /// An identifier that represents a session.
    typealias SessionID = UUID

}
