//
//  MaestroDeepLink.swift
//  Maestro
//
//  Created by Antonio Pallares on 7/30/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import RevenueCat

/// Deep links E2E tests use to change the app's behaviour without restarting it.
///
/// Launch arguments only reach a fresh process, so flows that need the session (and its warm caches) to
/// survive a background/foreground cycle change behaviour through these instead.
enum MaestroDeepLink {

    /// `rcmaestro://force-server-error-strategy?value=remote_config_killswitch`
    case forceServerErrorStrategy(Constants.ForceServerErrorStrategy)

    /// `rcmaestro://sync-attributes-and-offerings`
    ///
    /// The only way a test can provoke a `/v1/config` request mid-session: the refresh on foreground is
    /// stale-gated to 5 minutes, which no flow is going to wait out.
    case syncAttributesAndOfferings

    static let scheme = "rcmaestro"

    init?(url: URL) {
        guard url.scheme == Self.scheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        switch components.host {
        case "force-server-error-strategy":
            guard let value = components.queryItems?.first(where: { $0.name == "value" })?.value,
                  let strategy = Constants.ForceServerErrorStrategy(rawValue: value) else {
                return nil
            }
            self = .forceServerErrorStrategy(strategy)

        case "sync-attributes-and-offerings":
            self = .syncAttributesAndOfferings

        default:
            return nil
        }
    }

    func apply() {
        switch self {
        case .forceServerErrorStrategy(let strategy):
            print("Maestro: forcing server error strategy '\(strategy.rawValue)'")
            ForceServerErrorStrategyStore.update(to: strategy)

        case .syncAttributesAndOfferings:
            print("Maestro: syncing attributes and offerings")
            Purchases.shared.syncAttributesAndOfferingsIfNeeded { _, _ in }
        }
    }

}
