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
    typealias AlertFactory = @MainActor (
        _ host: UIViewController,
        _ title: String,
        _ message: String,
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
    private let alertFactory: AlertFactory
    private var presentation: Presentation?
    private var pendingPresentation: Presentation?

    init(
        presentationContextProvider: @escaping PresentationContextProvider = {
            UIApplication.extensionSafeApplication?.currentPresentationViewController
        },
        alertFactory: @escaping AlertFactory = DefaultErrorPresenter.makeAlert
    ) {
        self.presentationContextProvider = presentationContextProvider
        self.alertFactory = alertFactory
    }

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        let next = Presentation(params: params, completion: completion)

        if let current = self.presentation {
            let superseded = self.pendingPresentation
            self.pendingPresentation = next
            superseded?.completion.complete(.retry)
            self.finish(current, result: .retry)
        } else {
            self.beginPresentation(next)
        }
    }

    private func beginPresentation(_ current: Presentation) {
        guard let host = self.presentationContextProvider() else {
            Logger.error("Cannot present checkpoint error: no presentation context found.")
            current.completion.complete(current.params.flowCanContinue ? .retry : .continue)
            return
        }

        self.presentation = current
        let content = LocalizedAlertError.Content(error: current.params.error as NSError)
        current.alertController = self.alertFactory(
            host,
            content.title,
            content.message,
            { [weak self, weak current] in
                guard let self, let current else { return }
                self.acknowledge(current)
            }
        )
    }

    private func acknowledge(_ current: Presentation) {
        self.finish(
            current,
            result: current.params.flowCanContinue ? .retry : .continue
        )
    }

    private func finish(
        _ current: Presentation,
        result: ErrorPresentationCompletion.Result
    ) {
        guard self.presentation === current, !current.isFinishing else { return }
        current.isFinishing = true

        let completed = { [self] in
            current.completion.complete(result)
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
        title: String,
        message: String,
        acknowledged: @escaping @MainActor () -> Void
    ) -> UIViewController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okTitle = Bundle.revenueCatUI.localizedString(forKey: "OK", value: "OK", table: nil)
        alert.addAction(UIAlertAction(title: okTitle, style: .default) { _ in acknowledged() })
        host.present(alert, animated: true)
        return alert
    }

}
#else
@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class DefaultErrorPresenter: ErrorPresenter {

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        completion.complete(params.flowCanContinue ? .retry : .continue)
    }

}
#endif
