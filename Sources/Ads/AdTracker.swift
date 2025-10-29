//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdTracker.swift
//
//  Created by RevenueCat on 1/15/25.

import Foundation

#if ENABLE_AD_EVENTS_TRACKING

/**
 Tracks ad-related events to RevenueCat.

 Use this class to report ad impressions, clicks, and revenue to RevenueCat alongside your subscription data.
 This enables comprehensive LTV tracking across subscriptions and ad monetization.

 ## Usage

 Access the ad tracker through the `Purchases` singleton:

 ```swift
 let adTracker = Purchases.shared.adTracker
 ```

 ## Example

 ```swift
 // Track an ad impression
 await Purchases.shared.adTracker.trackAdDisplayed(.init(
     networkName: "AdMob",
     mediatorName: .appLovin,
     placement: "home_screen",
     adUnitId: "ca-app-pub-123",
     adInstanceId: "instance-456"
 ))

 // Track ad revenue
 await Purchases.shared.adTracker.trackAdRevenue(.init(
     networkName: "AdMob",
     mediatorName: .appLovin,
     placement: "home_screen",
     adUnitId: "ca-app-pub-123",
     adInstanceId: "instance-456",
     revenueMicros: 1500000,  // $1.50
     currency: "USD",
     precision: .exact
 ))
 ```
 */
@_spi(Experimental) @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
@objc(RCAdTracker)
public final class AdTracker: NSObject {

    private let eventsManager: EventsManagerType?

    internal init(eventsManager: EventsManagerType?) {
        self.eventsManager = eventsManager
        super.init()
    }

    /**
     Tracks when an ad impression is displayed.

     Call this method from your ad SDK's impression callback to report ad displays to RevenueCat.
     This enables RevenueCat to track ad impressions alongside your subscription revenue.

     - Parameter data: The displayed ad event data

     ## Example:
     ```swift
     await Purchases.shared.adTracker.trackAdDisplayed(.init(
         networkName: "AdMob",
         mediatorName: .appLovin,
         placement: "home_screen",
         adUnitId: "ca-app-pub-123",
         adInstanceId: "instance-456"
     ))
     ```
     */
    @_spi(Experimental) public func trackAdDisplayed(_ data: AdDisplayed) async {
        let event = AdEvent.displayed(.init(id: UUID(), date: Date()), data)
        await self.eventsManager?.track(featureEvent: event)
    }

    /**
     Tracks when an ad is opened or clicked.

     Call this method from your ad SDK's click callback to report ad interactions to RevenueCat.

     - Parameter data: The opened/clicked ad event data

     ## Example:
     ```swift
     await Purchases.shared.adTracker.trackAdOpened(.init(
         networkName: "AdMob",
         mediatorName: .appLovin,
         placement: "home_screen",
         adUnitId: "ca-app-pub-123",
         adInstanceId: "instance-456"
     ))
     ```
     */
    @_spi(Experimental) public func trackAdOpened(_ data: AdOpened) async {
        let event = AdEvent.opened(.init(id: UUID(), date: Date()), data)
        await self.eventsManager?.track(featureEvent: event)
    }

    /**
     Tracks ad revenue from an impression.

     Call this method from your ad SDK's revenue callback to report ad revenue to RevenueCat.
     This enables comprehensive LTV tracking across subscriptions and ad monetization.

     - Parameter data: The ad revenue data including amount, currency, and precision

     ## Example:
     ```swift
     await Purchases.shared.adTracker.trackAdRevenue(.init(
         networkName: "AdMob",
         mediatorName: .appLovin,
         placement: "home_screen",
         adUnitId: "ca-app-pub-123",
         adInstanceId: "instance-456",
         revenueMicros: 1500000,  // $1.50
         currency: "USD",
         precision: .exact
     ))
     ```
     */
    @_spi(Experimental) public func trackAdRevenue(_ data: AdRevenue) async {
        let event = AdEvent.revenue(.init(id: UUID(), date: Date()), data)
        await self.eventsManager?.track(featureEvent: event)
    }

    // MARK: - Objective-C Compatible Methods

    /**
     Tracks when an ad impression is displayed (Objective-C compatible).

     Call this method from your ad SDK's impression callback to report ad displays to RevenueCat.
     This is the completion handler version for Objective-C compatibility.

     - Parameters:
       - data: The displayed ad event data
       - completion: Called when the tracking is complete
     */
    @_spi(Experimental) @objc public func trackAdDisplayed(_ data: AdDisplayed, completion: @escaping () -> Void) {
        Task {
            await self.trackAdDisplayed(data)
            completion()
        }
    }

    /**
     Tracks when an ad is opened or clicked (Objective-C compatible).

     Call this method from your ad SDK's click callback to report ad interactions to RevenueCat.
     This is the completion handler version for Objective-C compatibility.

     - Parameters:
       - data: The opened/clicked ad event data
       - completion: Called when the tracking is complete
     */
    @_spi(Experimental) @objc public func trackAdOpened(_ data: AdOpened, completion: @escaping () -> Void) {
        Task {
            await self.trackAdOpened(data)
            completion()
        }
    }

    /**
     Tracks ad revenue from an impression (Objective-C compatible).

     Call this method from your ad SDK's revenue callback to report ad revenue to RevenueCat.
     This is the completion handler version for Objective-C compatibility.

     - Parameters:
       - data: The ad revenue data including amount, currency, and precision
       - completion: Called when the tracking is complete
     */
    @_spi(Experimental) @objc public func trackAdRevenue(_ data: AdRevenue, completion: @escaping () -> Void) {
        Task {
            await self.trackAdRevenue(data)
            completion()
        }
    }

}

#endif
