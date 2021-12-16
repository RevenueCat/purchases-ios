//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsHelper.swift
//
//  Created by Andrés Boedo on 16/8/21.

import StoreKit

class ManageSubscriptionsHelper {

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

#if os(iOS) || os(macOS)

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscriptions(completion: @escaping (Result<Void, Error>) -> Void) {
        let currentAppUserID = identityManager.currentAppUserID
        customerInfoManager.customerInfo(appUserID: currentAppUserID) { maybeCustomerInfo, maybeError in
            if let error = maybeError {
                let message = Strings.failed_to_get_management_url_error_unknown(error: error)
                completion(.failure(ErrorUtils.customerInfoError(withMessage: message.description, error: error)))
                return
            }

            guard let customerInfo = maybeCustomerInfo else {
                let message = Strings.failed_to_get_management_url_nil_customer_info
                completion(.failure(ErrorUtils.customerInfoError(withMessage: message.description)))
                return
            }

            guard let managementURL = customerInfo.managementURL else {
                Logger.debug(Strings.management_url_nil_opening_default)
                guard let appleSubscriptionsURL = self.systemInfo.appleSubscriptionsURL else {
                    let message = Strings.cant_form_apple_subscriptions_url
                    completion(.failure(ErrorUtils.systemInfoError(withMessage: message.description)))
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

#endif

}

@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension ManageSubscriptionsHelper {

    func showAppleManageSubscriptions(managementURL: URL,
                                      completion: @escaping (Result<Void, Error>) -> Void) {
#if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 15.0, *),
           // showManageSubscriptions doesn't work on iOS apps running on Apple Silicon
           // https://developer.apple.com/documentation/storekit/appstore/3803198-showmanagesubscriptions#
           !ProcessInfo().isiOSAppOnMac {
            _ = Task<Void, Never> {
                let result = await self.showSK2ManageSubscriptions()
                completion(result)
            }
            return
        }
#endif
        openURL(managementURL, completion: completion)
    }

    func openURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
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

        // NSInvocation is needed because the method takes three arguments
        // and performSelector works for up to 2
        typealias ClosureType = @convention(c) (AnyObject, Selector, NSURL, NSDictionary?, Any?) -> Void

        let selector: Selector = NSSelectorFromString("openURL:options:completionHandler:")
        let methodIMP: IMP! = application.method(for: selector)
        let openURLMethod = unsafeBitCast(methodIMP, to: ClosureType.self)
        openURLMethod(application, selector, url as NSURL, nil, nil)
    }

    @MainActor
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    func showSK2ManageSubscriptions() async -> Result<Void, Error> {
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
                  let message = Strings.failed_to_get_window_scene
                  return .failure(ErrorUtils.storeProblemError(withMessage: message.description))
        }

#if os(iOS)
        // Note: we're ignoring the result of AppStore.showManageSubscriptions(in:) because as of
        // iOS 15.2, it only returns after the sheet is dismissed, which isn't desired.
        _ = Task.init {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
                Logger.info(Strings.susbscription_management_sheet_dismissed)
            } catch {
                let message = Strings.error_from_appstore_show_manage_subscription(error: error)
                Logger.appleError(message)
            }
        }

        return .success(())
#else
        fatalError(Strings.manageSubscription.show_manage_subscriptions_called_in_unsupported_platform.description)
#endif
    }
#endif

}
