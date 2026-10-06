//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/LICENSE-2.0
//
//  ErrorPresenterDemo.swift
//
//  Created by Rick van der Linden.
//

import RevenueCat
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import UIKit

@MainActor
final class GlobalErrorPresenter: ErrorPresenter {

    static let shared = GlobalErrorPresenter()

    func present(params: ErrorPresentationParams, completion: ErrorPresentationCompletion) {
        ErrorPresenterDemo.present(style: .global, params: params, completion: completion)
    }

}

@MainActor
enum LocalErrorPresenter {

    static let shared: ErrorPresentationHandler = { params, completion in
        ErrorPresenterDemo.present(style: .localOverride, params: params, completion: completion)
    }

}

@MainActor
private enum ErrorPresenterDemo {

    enum Style {
        case global
        case localOverride

        var title: String {
            switch self {
            case .global: return "Global error presenter"
            case .localOverride: return "Local error presenter"
            }
        }
    }

    static func present(
        style: Style,
        params: ErrorPresentationParams,
        completion: ErrorPresentationCompletion
    ) {
        guard let presenter = Self.presentationViewController else {
            completion.complete(params.flowCanContinue ? .retry : .continue)
            return
        }

        let alert = UIAlertController(
            title: style.title,
            message: Self.message(for: params),
            preferredStyle: .alert
        )
        if params.flowCanContinue {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                completion.complete(.retry)
            })
        }
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            completion.complete(.continue)
        })
        alert.addAction(UIAlertAction(title: "Back", style: .cancel) { _ in
            completion.complete(.navigateBack)
        })
        presenter.present(alert, animated: true)
    }

    private static func message(for params: ErrorPresentationParams) -> String {
        return "Checkpoint · \(params.checkpointIdentifier)\n\n" +
            "\(params.error.localizedDescription)\n\n" +
            "Flow can continue · \(params.flowCanContinue ? "yes" : "no")"
    }

    private static var presentationViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootViewController = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }

        var viewController = rootViewController
        while let presentedViewController = viewController.presentedViewController {
            viewController = presentedViewController
        }
        return viewController
    }

}
