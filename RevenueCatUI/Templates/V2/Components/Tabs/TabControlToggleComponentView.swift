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
            .toggleStyle(
                CustomToggleStyle(
                    thumbColorOn: self.viewModel.thumbColorOn,
                    thumbColorOff: self.viewModel.thumbColorOff,
                    trackColorOn: self.viewModel.trackColorOn,
                    trackColorOff: self.viewModel.trackColorOff
                )
            )
            .labelsHidden()
        .onChangeOf(self.isOn) { newValue in
            self.tabControlContext.selectedIndex = newValue ? 1 : 0
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
                withAnimation(.smooth(duration: 0.2)) {
                    configuration.isOn.toggle()
                }
            }
    }
}

#endif
