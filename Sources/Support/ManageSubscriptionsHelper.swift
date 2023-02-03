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
    private let currentUserProvider: CurrentUserProvider

    init(systemInfo: SystemInfo,
         customerInfoManager: CustomerInfoManager,
         currentUserProvider: CurrentUserProvider) {
        self.systemInfo = systemInfo
        self.customerInfoManager = customerInfoManager
        self.currentUserProvider = currentUserProvider
    }

#if os(iOS) || os(macOS)

    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showManageSubscriptions(completion: @escaping (Result<Void, PurchasesError>) -> Void) {
        let currentAppUserID = self.currentUserProvider.currentAppUserID
        self.customerInfoManager.customerInfo(appUserID: currentAppUserID,
                                              fetchPolicy: .cachedOrFetched) { @Sendable result in
            let result: Result<URL, PurchasesError> = result
                .mapError { error in
                    let message = Strings.failed_to_get_management_url_error_unknown(error: error)
                    return ErrorUtils.customerInfoError(withMessage: message.description, error: error)
                }
                .flatMap { customerInfo in
                    guard let managementURL = customerInfo.managementURL else {
                        Logger.debug(Strings.management_url_nil_opening_default)

                        return .success(SystemInfo.appleSubscriptionsURL)
                    }

                    return .success(managementURL)
                }

            switch result {
            case let .success(url):
                if SystemInfo.isAppleSubscription(managementURL: url) {
                    self.showAppleManageSubscriptions(managementURL: url, completion: completion)
                } else {
                    self.openURL(url, completion: completion)
                }

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

#endif

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension ManageSubscriptionsHelper: @unchecked Sendable {}

// MARK: - Private

@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension ManageSubscriptionsHelper {

    func showAppleManageSubscriptions(managementURL: URL,
                                      completion: @escaping (Result<Void, PurchasesError>) -> Void) {
#if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 15.0, *),
           // showManageSubscriptions doesn't work on iOS apps running on Apple Silicon
           // https://developer.apple.com/documentation/storekit/appstore/3803198-showmanagesubscriptions#
           !ProcessInfo().isiOSAppOnMac {
            Async.call(with: completion) {
                return await self.showSK2ManageSubscriptions()
            }
            return
        }
#endif
        openURL(managementURL, completion: completion)
    }

    func openURL(_ url: URL, completion: @escaping (Result<Void, PurchasesError>) -> Void) {
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
    func showSK2ManageSubscriptions() async -> Result<Void, PurchasesError> {
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
                  let message = Strings.failed_to_get_window_scene
                  return .failure(ErrorUtils.storeProblemError(withMessage: message.description))
        }

#if os(iOS)
        // Note: we're ignoring the result of AppStore.showManageSubscriptions(in:) because as of
        // iOS 15.2, it only returns after the sheet is dismissed, which isn't desired.
        _ = Task<Void, Never> {
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
