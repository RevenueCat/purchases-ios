//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentView.swift
//
//  Created by Josh Holtz on 1/9/25.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabControlToggleComponentView: View {

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var packageContext: PackageContext

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition
    
    @EnvironmentObject
    private var tabControlContext: TabControlContext

    private let viewModel: TabControlToggleComponentViewModel
    let onDismiss: () -> Void
    
    @State
    private var isOn: Bool = false

    init(viewModel: TabControlToggleComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
        .onChangeOf(self.isOn) { newValue in
            self.tabControlContext.selectedIndex = newValue ? 1 : 0
        }
    }

}

#if DEBUG

// swiftlint:disable type_body_length
//@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
//struct TabControlComponentView_Previews: PreviewProvider {
//    
//    static let tabControlContext = TabControlContext(
//        controlStackViewModel: try! .init(
//            component: .init(
//                components: []),
//            viewModels: [],
//            uiConfigProvider: .init(
//                uiConfig: PreviewUIConfig.make()
//            )
//        )
//    )
//
//    static var previews: some View {
//        // Default
//        TabControlComponentView(
//            // swiftlint:disable:next force_try
//            viewModel: try! .init(
//                component: .init(),
//                uiConfigProvider: .init(uiConfig: PreviewUIConfig.make())
//            ),
//            onDismiss: {}
//        )
//        .environmentObject(tabControlContext)
//        .previewRequiredEnvironmentProperties()
//        .previewLayout(.sizeThatFits)
//        .previewDisplayName("Default")
//    }
//}

#endif

#endif
