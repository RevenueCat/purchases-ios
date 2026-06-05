//
//  PurchasesDeepLinkAPI.swift
//  APITesters
//
//  Created by Dave DeLong on 6/4/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import RevenueCat
import RevenueCatUI

#if os(iOS)
import UIKit

@available(iOS 15.0, macOS 12.0, *)
@MainActor
private func checkPurchasesPaywallPreviewDeepLinkHandler(_ url: URL, _ window: UIWindow?) {

    let _: Bool = Purchases.shared.presentPaywall(from: url, window: window)

}
#endif
