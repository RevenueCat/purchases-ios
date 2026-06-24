//
//  RemoteConfigSources.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 24/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

// Stubs for the `api` / `blob` source descriptors carried by the `sources` topic of the
// `/v2/config` response. Parsing them out of the topic content is not wired up here yet.

struct ApiSource: WeightedSource, Equatable {

    let id: String
    let url: String
    let priority: Int
    let weight: Int

}

struct BlobSource: WeightedSource, Equatable {

    let id: String
    let urlFormat: String
    let priority: Int
    let weight: Int

}
