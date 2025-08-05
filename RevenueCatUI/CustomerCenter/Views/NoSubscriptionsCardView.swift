//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NoSubscriptionsCardView.swift
//
//  Created by Facundo Menzella on 26/5/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsCardView: View {

    @Environment(\.colorScheme)
    private var colorScheme

    private let title: String
    private let subtitle: String

    init(
        title: String,
        subtitle: String
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    init(
        localization: CustomerCenterConfigData.Localization
    ) {
        self.init(
            title: localization[.noSubscriptionsFound],
            subtitle: localization[.tryCheckRestore]
        )
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(alignment: .center)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
                .frame(alignment: .leading)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color(colorScheme == .light
                          ? UIColor.secondarySystemFill
                          : UIColor.tertiarySystemBackground))
    }
}

private extension PurchaseInformation {
    var shoulShowPricePaid: Bool {
        renewalPrice != nil || expirationDate != nil
    }
}

private extension RefundRequestStatus {

    var icon: Image? {
        switch self {
        case .error:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .success:
            return Image(systemName: "info.circle.fill")
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }

    func subtitle(
        localization: CustomerCenterConfigData.Localization
    ) -> String? {
        switch self {
        case .error:
            return localization[.refundErrorGeneric]
        case .success:
            return localization[.refundSuccess]
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsCardView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            ScrollViewWithOSBackground {
                NoSubscriptionsCardView(localization: CustomerCenterConfigData.default.localization)
                    .cornerRadius(10)
                    .padding([.leading, .trailing])
            }
            .preferredColorScheme(colorScheme)
        }
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
