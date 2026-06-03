//
//  Tracking.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)

/// Namespace for the AdMob adapter's RevenueCat ad-tracking subsystem.
///
/// All types that wire AdMob events through to RevenueCat's ad-tracking pipeline live as
/// nested members of this caseless enum. The enum has no cases, so it cannot be instantiated;
/// it exists purely as a compile-time grouping.
@available(iOS 15.0, *)
internal enum Tracking {}

#endif
