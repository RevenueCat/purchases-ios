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

#if !os(tvOS) // For Paywalls V2

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
    private let onDismiss: () -> Void

    @State
    private var isOn: Bool = false

    init(viewModel: TabControlToggleComponentViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(
                CustomToggleStyle(
                    thumbColorOn: self.viewModel.thumbColorOn,
                    thumbColorOff: self.viewModel.thumbColorOff,
                    trackColorOn: self.viewModel.trackColorOn,
                    trackColorOff: self.viewModel.trackColorOff
                )
            )
            .labelsHidden()
            .onAppear {
                let tabIds = tabControlContext.tabIds
                let selectedId = tabControlContext.selectedTabId
                self.isOn = tabIds.indices.contains(1) && selectedId == tabIds[1]
            }
            .onChangeOf(self.isOn) { newValue in
                let tabIds = tabControlContext.tabIds
                guard tabIds.count >= 2 else { return }

                tabControlContext.selectedTabId = newValue ? tabIds[1] : tabIds[0]
            }
    }

}

private struct CustomToggleStyle: ToggleStyle {

    var thumbColorOn: Color
    var thumbColorOff: Color
    var trackColorOn: Color
    var trackColorOff: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .circular)
            .fill(configuration.isOn ? trackColorOn : trackColorOff)
            .frame(width: 50, height: 30)
            .overlay(
                Circle()
                    .fill(configuration.isOn ? thumbColorOn : thumbColorOff)
                    .padding(2)
                    .offset(x: configuration.isOn ? 10 : -10)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isOn.toggle()
                }
            }
    }
}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabControlToggleComponentView_Previews: PreviewProvider {

    // swiftlint:disable:next force_try
    static let controlStackViewModel = try! StackComponentViewModel(
        component: .init(components: []),
        localizationProvider: .init(
            locale: .init(identifier: "en-US"),
            localizedStrings: [:]),
        colorScheme: .light
    )

    static var previews: some View {
        // Off
        TabControlToggleComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    defaultValue: false,
                    thumbColorOn: .init(light: .hex("#00ff00")),
                    thumbColorOff: .init(light: .hex("#ff0000")),
                    trackColorOn: .init(light: .hex("#dedede")),
                    trackColorOff: .init(light: .hex("#bebebe"))
                ),
                uiConfigProvider: .init(uiConfig: PreviewMock.uiConfig),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .padding()
        .previewRequiredPaywallsV2Properties()
        .environmentObject(
            TabControlContext(
                controlStackViewModel: controlStackViewModel,
                tabIds: ["1", "2"],
                defaultTabId: "1"
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Off")

        // On
        TabControlToggleComponentView(
            // swiftlint:disable:next force_try
            viewModel: try! .init(
                component: .init(
                    defaultValue: true,
                    thumbColorOn: .init(light: .hex("#00ff00")),
                    thumbColorOff: .init(light: .hex("#ff0000")),
                    trackColorOn: .init(light: .hex("#dedede")),
                    trackColorOff: .init(light: .hex("#bebebe"))
                ),
                uiConfigProvider: .init(uiConfig: PreviewMock.uiConfig),
                colorScheme: .light
            ),
            onDismiss: {}
        )
        .padding()
        .previewRequiredPaywallsV2Properties()
        .environmentObject(
            TabControlContext(
                controlStackViewModel: controlStackViewModel,
                tabIds: ["1", "2"],
                defaultTabId: "2"
            )
        )
        .previewLayout(.sizeThatFits)
        .previewDisplayName("On")
    }

}

#endif

#endif
