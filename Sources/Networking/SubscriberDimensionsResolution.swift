//
//  SubscriberDimensionsResolution.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// The result of reading the optional `subscriber_dimensions` topic.
///
/// `notConfigured` means a committed config omits the topic. `unavailable` means the SDK could not produce
/// dimensions from the configuration it received.
enum SubscriberDimensionsResolution: Equatable, Sendable {

    case resolved(SubscriberDimensions)
    case notConfigured
    case unavailable

}
