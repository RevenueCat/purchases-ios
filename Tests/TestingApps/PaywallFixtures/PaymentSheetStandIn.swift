//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaymentSheetStandIn.swift

import UIKit

/// Stands in for the App Store payment sheet when the device locks over it (#7864).
///
/// The real sheet asks for a password, so a keyboard is up while it shows. When the device locks,
/// iOS dismisses the sheet with the app in the background and StoreKit reports a cancel. This shows
/// a focused text field on top of the paywall, outside its view tree, and takes it down in the
/// background the same way. It shares the paywall's window so UI tests can still read the paywall.
@MainActor
enum PaymentSheetStandIn {

    static let environmentKey = "PAYWALL_PAYMENT_SHEET"
    static let dismissedByLock = "dismissed_by_lock"

    static var isRequested: Bool {
        ProcessInfo.processInfo.environment[Self.environmentKey] == Self.dismissedByLock
    }

    static func presentUntilBackgrounded() async {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else { return }

        let field = UITextField()
        field.accessibilityIdentifier = "payment_sheet_password"
        field.isSecureTextEntry = true
        field.borderStyle = .roundedRect
        field.frame = CGRect(x: 16, y: window.safeAreaInsets.top, width: 240, height: 34)
        window.addSubview(field)
        field.becomeFirstResponder()

        for await _ in NotificationCenter.default.notifications(
            named: UIApplication.didEnterBackgroundNotification
        ) {
            break
        }

        field.removeFromSuperview()
    }

}
