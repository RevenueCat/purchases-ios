//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionModalHelper.swift
//
//  Created by Andrés Boedo on 16/8/21.

import StoreKit

@available(iOS 9.0, *)
@available(macOS 10.12, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@objc public class ManageSubscriptionsModalHelper: NSObject {
    private let systemInfo: SystemInfo
    private let purchaserInfoManager: PurchaserInfoManager
    private let identityManager: IdentityManager

    @objc public init(systemInfo: SystemInfo,
                      purchaserInfoManager: PurchaserInfoManager,
                      identityManager: IdentityManager) {
        self.systemInfo = systemInfo
        self.purchaserInfoManager = purchaserInfoManager
        self.identityManager = identityManager
    }

    @objc public func showManageSubscriptionModal() {
        let currentAppUserID = identityManager.currentAppUserID
        purchaserInfoManager.purchaserInfo(appUserID: currentAppUserID) { purchaserInfo, error in
            if let error = error {
                Logger.error("there was an error getting purchaserInfo: \(error.localizedDescription)")
                return
            }

            guard let purchaserInfo = purchaserInfo else {
                Logger.error("there was no error but purchaserInfo is nil!")
                return
            }

            guard let managementURL = purchaserInfo.managementURL else {
                Logger.debug("managementURL is nil, opening iOS subscription management page")
                if let appleSubscriptionsURL = self.systemInfo.appleSubscriptionsURL {
                    self.showAppleManageSubscriptions(managementURL: appleSubscriptionsURL)
                }
                return
            }

            if self.systemInfo.isAppleSubscription(managementURL: managementURL) {
                self.showAppleManageSubscriptions(managementURL: managementURL)
                return
            }

            self.openURL(managementURL)
        }
    }
}

@available(iOS 9.0, *)
@available(macOS 10.12, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension ManageSubscriptionsModalHelper {

    func showAppleManageSubscriptions(managementURL: URL) {
#if os(iOS)
        if #available(iOS 15.0, *) {
            Task.init {
                await self.showSK2ManageSubscriptions()
            }
            return
        }
#endif
        self.openURL(managementURL)
    }

    func openURL(_ url: URL) {
#if os(iOS)
        self.openURLIfNotAppExtension(url: url)
#elseif os(macOS)
        NSWorkspace.shared.open(url)
#endif
    }

#if os(iOS)
    func openURLIfNotAppExtension(url: URL) {
        guard !systemInfo.isAppExtension,
              let application = systemInfo.sharedUIApplication else { return }

        if #available(iOS 10.0, *) {
            // NSInvocation is needed because the method takes three arguments
            // and performSelector works for up to 2
            typealias ClosureType = @convention(c) (AnyObject, Selector, NSURL, NSDictionary?, Any?) -> Void

            let selector: Selector = NSSelectorFromString("openURL:options:completionHandler:")
            let methodIMP: IMP! = application.method(for: selector)
            let openURLMethod = unsafeBitCast(methodIMP, to: ClosureType.self)
            openURLMethod(application, selector, url as NSURL, nil, nil)
        } else {
            let selector = NSSelectorFromString("openURL:")
            systemInfo.sharedUIApplication?.perform(selector, with: url)
        }
    }

    @MainActor
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    func showSK2ManageSubscriptions() async {
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
            Logger.error("couldn't get window")
            return
        }

        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch let error {
            Logger.error("error when trying to show manage subscription: \(error.localizedDescription)")
        }
    }
#endif

}
