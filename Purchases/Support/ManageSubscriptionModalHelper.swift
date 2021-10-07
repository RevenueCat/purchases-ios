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

enum ManageSubscriptionsModalError: Error {

    case couldntGetCustomerInfo(message: String)
    case couldntGetWindowScene
    case storeKitShowManageSubscriptionsFailed(error: Error)
    case couldntGetAppleSubscriptionsURL

}

extension ManageSubscriptionsModalError: CustomStringConvertible {

    var description: String {
        switch self {
        case .couldntGetCustomerInfo(let message):
            return "Failed to get managemementURL from PurchaserInfo. Details: \(message)"
        case .couldntGetWindowScene:
            return "Failed to get UIWindowScene"
        case .storeKitShowManageSubscriptionsFailed(let error):
            return "Error when trying to show manage subscription: \(error.localizedDescription)"
        case .couldntGetAppleSubscriptionsURL:
            return "Error when trying to form the Apple Subscriptions URL."
        }
    }

}

class ManageSubscriptionsModalHelper {

    private let systemInfo: SystemInfo
    private let customerInfoManager: CustomerInfoManager
    private let identityManager: IdentityManager

    init(systemInfo: SystemInfo,
         customerInfoManager: CustomerInfoManager,
         identityManager: IdentityManager) {
        self.systemInfo = systemInfo
        self.customerInfoManager = customerInfoManager
        self.identityManager = identityManager
    }

    @available(iOS 9.0, *)
    @available(macOS 10.12, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscriptionModal(completion: @escaping (Result<Void, ManageSubscriptionsModalError>) -> Void) {
        let currentAppUserID = identityManager.currentAppUserID
        customerInfoManager.customerInfo(appUserID: currentAppUserID) { maybeCustomerInfo, maybeError in
            if let error = maybeError {
                completion(.failure(.couldntGetCustomerInfo(message: error.localizedDescription)))
                return
            }

            guard let customerInfo = maybeCustomerInfo else {
                completion(.failure(.couldntGetCustomerInfo(message: "customerInfo is nil.")))
                return
            }

            guard let managementURL = customerInfo.managementURL else {
                Logger.debug(Strings.purchase.management_url_nil_opening_default)
                guard let appleSubscriptionsURL = self.systemInfo.appleSubscriptionsURL else {
                    completion(.failure(.couldntGetAppleSubscriptionsURL))
                    return
                }
                self.showAppleManageSubscriptions(managementURL: appleSubscriptionsURL, completion: completion)
                return
            }

            if self.systemInfo.isAppleSubscription(managementURL: managementURL) {
                self.showAppleManageSubscriptions(managementURL: managementURL, completion: completion)
                return
            }

            self.openURL(managementURL, completion: completion)
        }
    }

}

@available(iOS 9.0, *)
@available(macOS 10.12, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension ManageSubscriptionsModalHelper {

    func showAppleManageSubscriptions(managementURL: URL,
                                      completion: @escaping (Result<Void, ManageSubscriptionsModalError>) -> Void) {
#if os(iOS)
        if #available(iOS 15.0, *) {
            Task {
                let result = await self.showSK2ManageSubscriptions()
                completion(result)
            }
            return
        }
#endif
        openURL(managementURL, completion: completion)
    }

    func openURL(_ url: URL, completion: @escaping (Result<Void, ManageSubscriptionsModalError>) -> Void) {
#if os(iOS)
        openURLIfNotAppExtension(url: url)
#elseif os(macOS)
        NSWorkspace.shared.open(url)
#endif
        completion(.success(()))
    }

#if os(iOS)
    // we can't directly reference UIApplication.shared in case this SDK is embedded into an app extension.
    // so we ensure that it's not running in an app extension and use selectors to call UIApplication methods.
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
    func showSK2ManageSubscriptions() async -> Result<Void, ManageSubscriptionsModalError> {
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
                  return .failure(.couldntGetWindowScene)
        }

        do {

// todo: remove when this gets fixed.
// limiting to arm architecture since builds on beta 5 fail if other archs are included
#if os(iOS) && arch(arm64)
            try await AppStore.showManageSubscriptions(in: windowScene)
            return .success(())
#else
            fatalError("tried to call AppStore.showManageSubscriptions in a platform that doesn't support it!")
#endif
        } catch {
            return .failure(.storeKitShowManageSubscriptionsFailed(error: error))
        }
    }
#endif

}
