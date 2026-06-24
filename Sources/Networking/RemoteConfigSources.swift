//
//  RemoteConfigSources.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 24/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

// Stubs for the `api` / `blob` source descriptors carried by the `sources` topic of the `/v2/config`
// response. They model the selection metadata plus the per-kind connection detail (`url` vs
// `urlFormat`) so a `WeightedSourceSelector` can choose between them. Parsing these out of the
// `sources` topic content is intentionally not wired up here.

/// An API source: a base URL the SDK can send `/v2/config` (and related) requests to.
struct ApiSource: WeightedSource, Equatable {

    let id: String
    /// Base URL for API requests, e.g. `https://api.revenuecat.com/`.
    let url: String
    let priority: Int
    let weight: Int

}

/// A blob/asset source: a URL template the SDK expands with a `blob_ref` to fetch static blobs.
struct BlobSource: WeightedSource, Equatable {

    let id: String
    /// URL template containing a `{blob_ref}` placeholder, e.g.
    /// `https://assets.revenuecat.com/app-prefix/{blob_ref}`.
    let urlFormat: String
    let priority: Int
    let weight: Int

}
