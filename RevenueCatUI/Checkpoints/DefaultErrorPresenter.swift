//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultErrorPresenter.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import UIKit

/// Handles checkpoint error presentation when no custom presenter is configured.
@MainActor
@available(iOS 15.0, macOS 12.0, *)
final class DefaultErrorPresenter: ErrorPresenter {

    typealias PresentationContextProvider = @MainActor () -> UIViewController?
    typealias PreferredUILocaleProvider = @MainActor () -> String?
    typealias AlertFactory = @MainActor (
        _ host: UIViewController,
        _ title: String?,
        _ message: String,
        _ acknowledgementTitle: String,
        _ acknowledged: @escaping @MainActor () -> Void
    ) -> UIViewController

    private final class Presentation {
        let params: ErrorPresentationParams
        let completion: ErrorPresentationCompletion
        var alertController: UIViewController?
        var isFinishing = false

        init(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
            self.params = params
            self.completion = completion
        }
    }

    private let presentationContextProvider: PresentationContextProvider
    private let preferredUILocaleProvider: PreferredUILocaleProvider
    private let alertFactory: AlertFactory
    private var presentation: Presentation?
    private var pendingPresentation: Presentation?

    init(
        presentationContextProvider: @escaping PresentationContextProvider = {
            UIApplication.extensionSafeApplication?.currentPresentationViewController
        },
        preferredUILocaleProvider: @escaping PreferredUILocaleProvider = { nil },
        alertFactory: @escaping AlertFactory = { host, title, message, acknowledgementTitle, acknowledged in
            DefaultErrorPresenter.makeAlert(
                host: host,
                title: title,
                message: message,
                acknowledgementTitle: acknowledgementTitle,
                acknowledged: acknowledged
            )
        }
    ) {
        self.presentationContextProvider = presentationContextProvider
        self.preferredUILocaleProvider = preferredUILocaleProvider
        self.alertFactory = alertFactory
    }

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        let next = Presentation(params: params, completion: completion)

        if let current = self.presentation {
            let superseded = self.pendingPresentation
            self.pendingPresentation = next
            superseded?.completion.complete()
            self.finish(current)
        } else {
            self.beginPresentation(next)
        }
    }

    private func beginPresentation(_ current: Presentation) {
        guard let host = self.presentationContextProvider() else {
            Logger.error("Cannot present checkpoint error: no presentation context found.")
            current.completion.complete()
            return
        }

        self.presentation = current
        let localizedBundle = self.localizedBundle
        current.alertController = self.alertFactory(
            host,
            nil,
            current.params.localizedMessage(in: localizedBundle),
            localizedBundle.localizedString(forKey: "OK", value: "OK", table: nil),
            { [weak self, weak current] in
                guard let self, let current else { return }
                self.acknowledge(current)
            }
        )
    }

    private func acknowledge(_ current: Presentation) {
        self.finish(current)
    }

    private func finish(_ current: Presentation) {
        guard self.presentation === current, !current.isFinishing else { return }
        current.isFinishing = true

        let completed = { [self] in
            current.completion.complete()
            guard self.presentation === current else { return }

            self.presentation = nil
            if let next = self.pendingPresentation {
                self.pendingPresentation = nil
                self.beginPresentation(next)
            }
        }
        guard let alertController = current.alertController,
              alertController.presentingViewController != nil else {
            completed()
            return
        }
        current.alertController = nil
        alertController.dismiss(animated: false, completion: completed)
    }

    private static func makeAlert(
        host: UIViewController,
        title: String?,
        message: String,
        acknowledgementTitle: String,
        acknowledged: @escaping @MainActor () -> Void
    ) -> UIViewController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: acknowledgementTitle, style: .default) { _ in acknowledged() })
        host.present(alert, animated: true)
        return alert
    }

    private var localizedBundle: Bundle {
        guard let identifier = self.preferredUILocaleProvider() else {
            return .revenueCatUI
        }
        return Localization.localizedBundle(Locale(identifier: identifier))
    }

}

@available(iOS 15.0, macOS 12.0, *)
private extension ErrorPresentationParams {

    func localizedMessage(in bundle: Bundle) -> String {
        let error = self.error as NSError
        guard error.revenueCatErrorCode != .testStoreSimulatedPurchaseError else {
            return error.localizedDescription
        }

        let message: String
        if error.revenueCatErrorCode == .networkError || error.revenueCatErrorCode == .offlineConnectionError {
            message = "Couldn't connect. Check your internet connection and try again."
        } else if self.kind == .flowCouldNotBeShown {
            message = "This content couldn't be loaded. Please try again later."
        } else if self.kind == .flowResultSyncFailed {
            message = "Your purchases couldn't be verified. Please try again later."
        } else {
            switch error.revenueCatErrorCode {
            case .storeProblemError:
                message = "There was a problem with the store. Please try again later."
            case .purchaseNotAllowedError:
                message = "Purchases aren't allowed on this device."
            case .productNotAvailableForPurchaseError:
                message = "This product isn't available right now."
            case .productAlreadyPurchasedError:
                message = "You already own this product."
            case .paymentPendingError:
                message = "Your payment is pending. You'll get access once it's approved."
            default:
                message = "Something went wrong. Please try again."
            }
        }

        return bundle.localizedString(forKey: message, value: message, table: nil)
    }

}

private extension NSError {

    var revenueCatErrorCode: ErrorCode? {
        guard self.domain == ErrorCode.errorDomain else { return nil }
        return ErrorCode(rawValue: self.code)
    }

}
#else
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class DefaultErrorPresenter: ErrorPresenter {

    typealias PreferredUILocaleProvider = @MainActor () -> String?

    init(preferredUILocaleProvider: @escaping PreferredUILocaleProvider = { nil }) {}

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        completion.complete()
    }

}
#endif
