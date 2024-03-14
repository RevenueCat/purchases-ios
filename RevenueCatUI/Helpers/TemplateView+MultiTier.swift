//
//  TemplaterView+MultiTier.swift
//
//
//  Created by Nacho Soto on 2/12/24.
//

import SwiftUI

import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    func notify(selectedTier: PaywallData.Tier, selectedPackage: TemplateViewConfiguration.Package) -> some View {
        self.preference(
            key: PaywallCurrentTierPreferenceKey.self,
            value: .init(tier: selectedTier, localizedName: selectedPackage.localization.tierName ?? "")
        )
    }

}

// MARK: - Preference Key

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct PaywallCurrentTierPreferenceKey: PreferenceKey {

    struct Data: Equatable {
        var tier: PaywallData.Tier
        var localizedName: String
    }

    typealias Value = Data?

    static var defaultValue: Value = nil

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }

}
