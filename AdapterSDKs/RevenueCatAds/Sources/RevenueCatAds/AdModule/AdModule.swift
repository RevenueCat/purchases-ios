//
//  AdModule.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(PrebidMobile)
import RevenueCat
import UIKit

/// The seam between the public `RevenueCatAds` API and the third-party SDK that actually
/// requests and renders ads. Swapping the underlying SDK means providing another implementation.
@MainActor
protocol AdModule: AnyObject {

    func initialize(with configuration: ResolvedAdsConfiguration) throws

    func makeInterstitial(placementID: String) -> AdModuleInterstitial

}

@MainActor
protocol AdModuleInterstitial: AnyObject {

    var onEvent: ((AdModuleEvent) -> Void)? { get set }

    var isReady: Bool { get }

    /// The ad network that served the ad.
    var networkName: String { get }

    /// What the loaded ad earns per impression, when the underlying SDK exposes it.
    var revenue: AdModuleRevenue? { get }

    func load()

    func show(from viewController: UIViewController)

}

struct AdModuleRevenue: Equatable {

    let micros: Int
    let currency: String
    let precision: AdRevenue.Precision

}

enum AdModuleEvent {

    case loaded
    case failedToLoad(AdsError)
    case presented
    case impression
    case clicked
    case dismissed

}

#endif
