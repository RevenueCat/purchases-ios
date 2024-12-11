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
//  Created by Cesar de la Vega on 6/11/24.

protocol FeatureEvent: Encodable, Sendable {

    var feature: Feature { get }
    var eventDiscriminator: String? { get }

}
