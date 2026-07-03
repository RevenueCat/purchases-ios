//
//  Purchases+PreviewPaywall.swift
//  RevenueCat
//
//  Created by Dave DeLong on 6/4/26.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

extension Purchases {

    /// Attempts to present a paywall from a Preview Paywall deep link.
    ///
    /// This method parses the provided `URL` and attempts to extract information that correlates
    /// to a known offering and published paywall. If successful, this method returns `true` and
    /// attempts to present that paywall for previewing.
    ///
    /// The `viewController` parameter may be `nil`. If omitted, the SDK will attempt to locate a suitable
    /// view controller for presentation. If none can be found (for example, the app is backgrounded),
    /// a warning is logged and the paywall is not shown.
    ///
    /// Use this method when handling a request for your app to open a `URL`. For example:
    ///
    /// ```swift
    /// func myAppHandleOpenURL(_ url: URL) async {
    ///   // see if this is a WebRedemptionToken:
    ///   if let purchaseRedemption = Purchases.parseAsWebPurchaseRedemption(url) {
    ///     await Purchases.shared.redeemWebPurchase(purchaseRedemption)
    ///     return
    ///   }
    ///
    ///   if Purchases.shared.presentPaywall(from: url) == true {
    ///     // A paywall will be presented from an appropriate window
    ///     return
    ///   }
    ///
    ///   // continue with typical URL handling
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - url: The `URL` received by your application
    ///   - viewController: The view controller to present the paywall from. In unspecified (the default),
    ///   a suitable view controller will be chosen automatically.
    /// - Returns: `true` if the URL is a valid rc-paywall-preview URL and handling has begun; `false` otherwise.
    @available(iOS 15.0, macOS 12.0, *)
    @MainActor
    @objc public func presentPaywall(from url: URL, viewController: UIViewController?) -> Bool {

        // create the paywall view controller and show it off the provided window (if available)
        // otherwise, look for the key window of the .foregroundActive scene,
        // falling back to other scenes/windows if necessary
        var presentationContext = viewController

        if presentationContext == nil {
            presentationContext = UIApplication.shared
                                               .connectedScenes
                                               .compactMap { $0 as? UIWindowScene }
                                               .flatMap { scene -> [(UIScene.ActivationState, UIWindow)] in
                                                   // ignore unattached scenes
                                                   if scene.activationState == .unattached { return [] }
                                                   return scene.windows.map { (scene.activationState, $0) }
                                               }
                                               .sorted(by: { (left, right) in
                                                   // prefer windows from scenes with a lower (more foreground) state
                                                   if left.0 != right.0 { return left.0.rawValue < right.0.rawValue }
                                                   // if they have the same state, prefer a key window over non-key
                                                   return left.1.isKeyWindow
                                               })
                                               .compactMap(\.1.rootViewController)
                                               .first
        }

        return PreviewPaywallPresenter().handle(locateOffering: {
            return try await self.offerings().offering(identifier: $0)
        }, url: url, viewController: presentationContext)
    }

    /// Attempts to present a paywall from a Preview Paywall deep link.
    ///
    /// This method parses the provided `URL` and attempts to extract information that correlates
    /// to a known offering and published paywall. If successful, this method returns `true` and
    /// attempts to present that paywall for previewing.
    ///
    /// The `window` parameter is optional. If omitted, the SDK will attempt to locate a suitable
    /// foreground and key window for presentation. If no window can be found (for example,
    /// the app is backgrounded), a warning is logged and the paywall is not shown.
    ///
    /// Use this method when handling a request for your app to open a `URL`. For example:
    ///
    /// ```swift
    /// func myAppHandleOpenURL(_ url: URL) async {
    ///   // see if this is a WebRedemptionToken:
    ///   if let purchaseRedemption = Purchases.parseAsWebPurchaseRedemption(url) {
    ///     await Purchases.shared.redeemWebPurchase(purchaseRedemption)
    ///     return
    ///   }
    ///
    ///   if Purchases.shared.presentPaywall(from: url) == true {
    ///     // A paywall will be presented from an appropriate window
    ///     return
    ///   }
    ///
    ///   // continue with typical URL handling
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - url: The `URL` received by your application
    ///   - window: The window to present the paywall from. In unspecified,
    ///   a suitable window will be chosen automatically.
    /// - Returns: `true` if the URL is a valid rc-paywall-preview URL and handling has begun; `false` otherwise.
    @available(iOS 15.0, macOS 12.0, *)
    @MainActor
    @objc public func presentPaywall(from url: URL, window: UIWindow?) -> Bool {
        return self.presentPaywall(from: url, viewController: window?.rootViewController)
    }

    /// Attempts to present a paywall from a Preview Paywall deep link.
    ///
    /// This method parses the provided `URL` and attempts to extract information that correlates
    /// to a known offering and published paywall. If successful, this method returns `true` and
    /// attempts to present that paywall for previewing.
    ///
    /// The `window` parameter is optional. If omitted, the SDK will attempt to locate a suitable
    /// foreground and key window for presentation. If no window can be found (for example,
    /// the app is backgrounded), a warning is logged and the paywall is not shown.
    ///
    /// Use this method when handling a request for your app to open a `URL`. For example:
    ///
    /// ```swift
    /// func myAppHandleOpenURL(_ url: URL) async {
    ///   // see if this is a WebRedemptionToken:
    ///   if let purchaseRedemption = Purchases.parseAsWebPurchaseRedemption(url) {
    ///     await Purchases.shared.redeemWebPurchase(purchaseRedemption)
    ///     return
    ///   }
    ///
    ///   if Purchases.shared.presentPaywall(from: url) == true {
    ///     // A paywall will be presented from an appropriate window
    ///     return
    ///   }
    ///
    ///   // continue with typical URL handling
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - url: The `URL` received by your application
    ///   - window: The window to present the paywall from. In unspecified,
    ///   a suitable window will be chosen automatically.
    /// - Returns: `true` if the URL is a valid rc-paywall-preview URL and handling has begun; `false` otherwise.
    @available(iOS 15.0, macOS 12.0, *)
    @MainActor
    @objc public func presentPaywall(from url: URL, scene: UIWindowScene?) -> Bool {
        return self.presentPaywall(from: url, window: scene?.keyWindow)
    }

    /// Attempts to present a paywall from a Preview Paywall deep link.
    ///
    /// This method parses the provided `URL` and attempts to extract information that correlates
    /// to a known offering and published paywall. If successful, this method returns `true` and
    /// attempts to present that paywall for previewing, by locating a suitable foreground and key
    /// window for presentation. If no window can be found (for example, the app is backgrounded),
    /// a warning is logged and the paywall is not shown.
    ///
    /// Use this method when handling a request for your app to open a `URL`. For example:
    ///
    /// ```swift
    /// func myAppHandleOpenURL(_ url: URL) async {
    ///   // see if this is a WebRedemptionToken:
    ///   if let purchaseRedemption = Purchases.parseAsWebPurchaseRedemption(url) {
    ///     await Purchases.shared.redeemWebPurchase(purchaseRedemption)
    ///     return
    ///   }
    ///
    ///   if Purchases.shared.presentPaywall(from: url) == true {
    ///     // A paywall will be presented from an appropriate window
    ///     return
    ///   }
    ///
    ///   // continue with typical URL handling
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - url: The `URL` received by your application
    /// - Returns: `true` if the URL is a valid rc-paywall-preview URL and handling has begun; `false` otherwise.
    @available(iOS 15.0, macOS 12.0, *)
    @MainActor
    @objc public func presentPaywall(from url: URL) -> Bool {
        return self.presentPaywall(from: url, viewController: nil)
    }

}

@available(iOS 15.0, macOS 12.0, *)
struct PreviewPaywallPresenter {

    func handle(locateOffering: @escaping (String) async throws -> Offering?,
                url: URL,
                viewController: UIViewController?) -> Bool {

        // expected format: {customScheme}://rc-paywall-preview?offering_id={OFFERING_ID}&paywall_id={PAYWALL_ID}
        guard let parsed = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }

        guard parsed.host == "rc-paywall-preview" else { return false }

        let queryItems = parsed.queryItems ?? []

        guard queryItems.count >= 2 else {
            Logger.warning("Invalid rc-paywall-preview link. Expected 2+ parameters, but found \(queryItems.count)")
            return false
        }

        guard let offeringID = queryItems.first(where: { $0.name == "offering_id" })?.value,
                offeringID.isEmpty == false else {
            Logger.warning("Invalid rc-paywall-preview link: Bad offering_id parameter")
            return false
        }
        guard let paywallID = queryItems.first(where: { $0.name == "paywall_id" })?.value,
                paywallID.isEmpty == false else {
            Logger.warning("Invalid rc-paywall-preview link: Bad paywall_id parameter")
            return false
        }

        guard let presentationContext = viewController else {
            Logger.warning("Unable to locate suitable presentation context for paywall")
            return false
        }

        Task { @MainActor in
            // This is done in an async closure, because locating the offering
            // may need to wait for configuration to complete
            do {
                guard let offering = try await locateOffering(offeringID) else {
                    Logger.warning("Attempting to show paywall for offering \(offeringID), " +
                                   "but cannot locate a published offering with that id")
                    return
                }

                // there's a one-to-one relationship between paywalls and offerings
                // make sure that our parameters match reality
                guard offering.paywall?.id == paywallID else {
                    Logger.warning("Attempting to show paywall \(paywallID), " +
                                   "but it does not match the paywall associated with \(offeringID)")
                    return
                }

                let context = PresentedOfferingContext(offeringIdentifier: offeringID)
                let viewController = PaywallViewController(offeringIdentifier: offeringID,
                                                           presentedOfferingContext: context)
                presentationContext.present(viewController, animated: true)

            } catch {
                Logger.error(Strings.errorFetchingOfferings(error))
            }
        }

        return true
    }

}

#endif
