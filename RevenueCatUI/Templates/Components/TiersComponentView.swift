//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TiersComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI
// swiftlint:disable all

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TiersComponentView: View {

    let locale: Locale
    let component: PaywallComponent.TiersComponent

    @State private var selectedTierIndex = 0

    private var tiers: [PaywallComponent.TiersComponent.TierInfo] {
        return component.tiers
    }

    private var componentBeforeSelector: [PaywallComponent] {
        var selectorFound = false
        let before = tiers[selectedTierIndex].components.filter { component in
            if selectorFound == false {
                if case .tierSelector(_) = component {
                    selectorFound = true
                } else if case .tierToggle(_) = component {
                    selectorFound = true
                }
            }

            return !selectorFound
        }

        return selectorFound ? before : []
    }

    private var componentAfterSelector: [PaywallComponent] {
        var selectorFound = false
        let after = tiers[selectedTierIndex].components.filter { component in
            if selectorFound == false {
                if case .tierSelector(_) = component {
                    selectorFound = true
                } else if case .tierToggle(_) = component {
                    selectorFound = true
                }
            }

            return selectorFound
        }

        return selectorFound ? after : tiers[selectedTierIndex].components
    }

    var tierSelector: PaywallComponent.TierSelectorComponent? {
        return tiers[selectedTierIndex].components.compactMap { component in
            if case .tierSelector(let tierSelectorView) = component {
                return tierSelectorView
            }

            return nil
        }.first
    }

    var tierToggle: PaywallComponent.TierToggleComponent? {
        return tiers[selectedTierIndex].components.compactMap { component in
            if case .tierToggle(let tierToggle) = component {
                return tierToggle
            }

            return nil
        }.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ComponentsView(
                locale: locale,
                components: self.componentBeforeSelector
            )

            if let tierSelector {
                TierSelectorComponentView(
                    locale: locale,
                    component: tierSelector,
                    tiers: tiers,
                    selectedTierIndex: $selectedTierIndex
                )
            } else if let tierToggle {
                TierToggleComponentView(
                    locale: locale,
                    component: tierToggle,
                    tiers: tiers,
                    selectedTierIndex: $selectedTierIndex
                )
            } else {
                TierSelectorComponentView(
                    locale: locale,
                    component: .init(),
                    tiers: tiers,
                    selectedTierIndex: $selectedTierIndex
                )
            }

            ComponentsView(
                locale: locale,
                components: self.componentAfterSelector
            )
        }
    }

    struct TierSelectorComponentView: View {

        let locale: Locale
        let component: PaywallComponent.TierSelectorComponent
        let tiers: [PaywallComponent.TiersComponent.TierInfo]
        @Binding var selectedTierIndex: Int

        var body: some View {
            Picker("Options", selection: $selectedTierIndex) {
                ForEach(Array(self.tiers.map { $0.id }.enumerated()), id: \.offset) { index, item in
                    Text(
                        getLocalization(locale, self.tiers[index].displayName)
                    ).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .defaultVerticalPadding()
            .defaultHorizontalPadding()
        }
    }

    struct TierToggleComponentView: View {
        internal init(locale: Locale, component: PaywallComponent.TierToggleComponent, tiers: [PaywallComponent.TiersComponent.TierInfo], selectedTierIndex: Binding<Int>) {
            self.locale = locale
            self.component = component
            self.tiers = tiers
            self._selectedTierIndex = selectedTierIndex
            self.isOn = component.defaultValue
        }


        private let locale: Locale
        private let component: PaywallComponent.TierToggleComponent
        private let tiers: [PaywallComponent.TiersComponent.TierInfo]
        @Binding private var selectedTierIndex: Int

        @State private var isOn: Bool

        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Toggle(isOn: $isOn, label: {
                        Text(getLocalization(locale, component.text))
                    })
                    .onChangeOf(self.isOn, perform: { newValue in
                        self.selectedTierIndex = isOn ? 1 : 0
                    })
                    .defaultVerticalPadding()
                    .defaultHorizontalPadding()
                    Spacer()
                }
            }
        }
    }

}

#endif
