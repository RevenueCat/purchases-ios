//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfferCodePresenter.swift
//
//  Created by Will Taylor on 10/18/24.

import Foundation

@testable import RevenueCat

import UIKit

final class MockOfferCodePresenter: OfferCodePresenterType, @unchecked Sendable {

    var presentOfferCodeRedeemSheetCalled = false
    var presentOfferCodeRedeemSheetWindowScene: UIWindowScene?
    func presentOfferCodeRedeemSheet(windowScene: UIWindowScene) async throws {
        self.presentOfferCodeRedeemSheetCalled = true
        self.presentOfferCodeRedeemSheetWindowScene = windowScene
    }
}
