//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+CustomerCenterCompleted.swift
//
//  Created by Cesar de la Vega on 6/7/24.

import Foundation
import SwiftUI

public typealias CustomerCenterCompletedHandler = @MainActor @Sendable (_ status: CustomerCenterStatus) -> Void

extension View {

    public func onCustomerCenterCompleted(
        _ handler: @escaping CustomerCenterCompletedHandler
    ) -> some View {
        return self.modifier(CustomerCenterCompletedViewModifier(handler: handler))
    }

}

private struct CustomerCenterCompletedViewModifier: ViewModifier {

    let handler: CustomerCenterCompletedHandler

    init(handler: @escaping CustomerCenterCompletedHandler) {
        self.handler = handler
    }

    func body(content: Content) -> some View {
        content.onPreferenceChange(CustomerCenterResultPreferenceKey.self) { result in
            if let result {
                self.handler(result.status)
            }
        }
    }

}
