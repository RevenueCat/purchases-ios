//
//  CustomerCenterViewAPI.swift
//  RevenueCatUISwiftAPITester
//
//  Created by Will Taylor on 12/11/24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

#if canImport(UIKit) && os(iOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct TestViewPlusPresentCustomerCenter: View {

    @State private var isPresented = false

    var body: some View {
        EmptyView()
            .presentCustomerCenter(isPresented: $isPresented)
            .presentCustomerCenter(isPresented: $isPresented, onDismiss: {})
            .presentCustomerCenter(
                isPresented: $isPresented,
                customerCenterActionHandler: { _ in

                },
                onDismiss: {}
            )
    }
}
#endif
