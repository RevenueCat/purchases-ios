//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewPreferenceKeyTests.swift
//
//  Created by Facundo Menzella on 13/3/25.

@testable import RevenueCatUI
import SwiftUI
import Testing

@Suite
struct CustomerCenterActionWrapperTests {

    @Test
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    func testActionWrapperAndModifiers() async {
        let actionWrapper = await CustomerCenterActionWrapper()

        var onCustomerCenterRestoreStarted = false
        await confirmation { @MainActor confirmation1 in
            let testView = Text("test")
                .modifier(CustomerCenterActionViewModifier(actionWrapper: actionWrapper))
                .onCustomerCenterRestoreStarted {
                    onCustomerCenterRestoreStarted = true
                    confirmation1()
                }

            let view = UIHostingController(rootView: testView)
            let window = UIWindow()
            window.rootViewController = view
            window.makeKeyAndVisible()
            view.view.layoutIfNeeded()

            actionWrapper.handleAction(.restoreStarted)
            await Task.yield()
        }
    }
}
