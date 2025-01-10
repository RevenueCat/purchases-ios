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
struct TabControlComponentView: View {

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

    private let viewModel: TabControlComponentViewModel
    let onDismiss: () -> Void
    
    init(viewModel:  TabControlComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        StackComponentView(
            viewModel: try! .init(
                component: self.tabControlContext.controlStackViewModel.component,
                viewModels: self.tabControlContext.tabControlStackViews.enumerated().map({ index, tabStack in
                    return .genericViewContainer(.init(view: AnyView(
                        Button {
                            self.tabControlContext.selectedIndex = index
                        } label: {
                            StackComponentView(
                                viewModel: tabStack,
                                onDismiss: self.onDismiss
                            )
                        }
                    )))
                }),
                uiConfigProvider: self.tabControlContext.controlStackViewModel.uiConfigProvider
            ),
            onDismiss: self.onDismiss
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct GenericViewContainerViewModel {
    let view: AnyView
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
