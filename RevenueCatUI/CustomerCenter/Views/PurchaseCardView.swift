//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInformationCardView.swift
//
//  Created by Facundo Menzella on 13/5/25.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchaseInformationCardView: View {

    // swiftlint:disable file_length

    @Environment(\.colorScheme)
    private var colorScheme

    private let title: String
    private let subtitle: String?
    private let badge: Badge?

    private let accessibilityIdentifier: String

    private let storeTitle: String

    private let additionalIcon: Image?
    private let additionalInfo: String?

    private let showChevron: Bool

    init(
        title: String,
        storeTitle: String,
        accessibilityIdentifier: String,
        badge: PurchaseInformationCardView.Badge? = nil,
        additionalIcon: Image? = nil,
        additionalInfo: String? = nil,
        subtitle: String? = nil,
        showChevron: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.additionalIcon = additionalIcon
        self.additionalInfo = additionalInfo
        self.storeTitle = storeTitle
        self.showChevron = showChevron
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    init(
        purchaseInformation: PurchaseInformation,
        localization: CustomerCenterConfigData.Localization,
        accessibilityIdentifier: String,
        refundStatus: RefundRequestStatus? = nil,
        showChevron: Bool = true
    ) {
        self.title = purchaseInformation.title
        self.accessibilityIdentifier = accessibilityIdentifier

        if purchaseInformation.renewalDate != nil {
            self.subtitle = purchaseInformation.priceRenewalString(
                localizations: localization
            )
        } else if purchaseInformation.expirationDate != nil {
            self.subtitle = purchaseInformation.expirationString(
                localizations: localization
            )
        } else {
            self.subtitle = purchaseInformation.pricePaidString(localizations: localization)
        }

        self.additionalIcon = refundStatus?.icon
        self.additionalInfo = refundStatus?.subtitle(localization: localization)

        self.storeTitle = localization[purchaseInformation.storeLocalizationKey]
        self.showChevron = showChevron

        self.badge = Badge(
            purchaseInformation: purchaseInformation,
            localization: localization
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CompatibilityLabeledContent {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(alignment: .center)
                            .multilineTextAlignment(.leading)

                        if let badge {
                            badge
                        }
                    }
                    .padding(.bottom, 8)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                            .frame(alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }

                    Text(storeTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            } content: {
                HStack {
                    if showChevron {
                        Image(systemName: "chevron.forward")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.secondary)
                            .font(Font.system(size: 12, weight: .bold))
                    }
                }
            }
            .padding()
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))

            if let additionalInfo, let additionalIcon {
                HStack(alignment: .center, spacing: 12) {
                    additionalIcon
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.secondary)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)

                    Text(additionalInfo)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
        }
        #if compiler(>=5.9)
        .background(Color(colorScheme == .light
                          ? UIColor.secondarySystemFill
                          : UIColor.tertiarySystemBackground),
                    in: .rect(cornerRadius: CustomerCenterStylingUtilities.cornerRadius))
        #endif
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

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PurchaseInformationCardView {

    struct Badge: View {
        @Environment(\.colorScheme)
        private var colorScheme

        let title: String
        let id: String
        let backgroundColor: Color?
        let borderColor: Color
        var accessibilityIdentifier: String = "PurchaseInformationCardView.Badge"

        var body: some View {
            if #available(iOS 26.0, *) {
                Text(title)
                    .font(.caption2)
                    .bold()
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    #if compiler(>=5.9)
                    .background(backgroundColor ?? Color(
                        colorScheme == .light
                        ? UIColor.systemBackground
                        : UIColor.secondarySystemBackground
                    ), in: .capsule)
                    #endif
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .accessibilityIdentifier([accessibilityIdentifier, id].joined(separator: "_"))
            } else {
                Text(title)
                    .font(.caption2)
                    .bold()
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    #if compiler(>=5.9)
                    .background(backgroundColor ?? Color(
                        colorScheme == .light
                        ? UIColor.systemBackground
                        : UIColor.secondarySystemBackground
                    ), in: .rect(cornerRadius: 4))
                    #endif
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .accessibilityIdentifier([accessibilityIdentifier, id].joined(separator: "_"))
            }
        }

        static func cancelled(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.badgeCancelled],
                id: CCLocalizedString.badgeCancelled.rawValue,
                backgroundColor: Color(red: 242 / 256, green: 84 / 256, blue: 91 / 256, opacity: 0.15),
                borderColor: .clear
            )
        }

        static func lifetime(
            _ localizations: CustomerCenterConfigData.Localization
        ) -> Badge {
            Badge(
                title: localizations[.badgeLifetime],
                id: CCLocalizedString.badgeLifetime.rawValue,
                backgroundColor: nil,
                borderColor: Color(red: 60 / 256, green: 60 / 256, blue: 67 / 256, opacity: 0.29)
            )
        }

        static func cancelledTrial(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.badgeTrialCancelled],
                id: CCLocalizedString.badgeTrialCancelled.rawValue,
                backgroundColor: Color(red: 242 / 256, green: 84 / 256, blue: 91 / 256, opacity: 0.15),
                borderColor: .clear
            )
        }

        static func freeTrial(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.badgeFreeTrial],
                id: CCLocalizedString.badgeFreeTrial.rawValue,
                backgroundColor: Color(red: 245 / 256, green: 202 / 256, blue: 92 / 256, opacity: 0.2),
                borderColor: .clear
            )
        }

        static func active(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.active],
                id: CCLocalizedString.active.rawValue,
                backgroundColor: Color(red: 52 / 256, green: 199 / 256, blue: 89 / 256, opacity: 0.2),
                borderColor: .clear
            )
        }

        static func expired(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.expired],
                id: CCLocalizedString.expired.rawValue,
                backgroundColor: Color(red: 242 / 256, green: 242 / 256, blue: 247 / 256, opacity: 0.2),
                borderColor: .clear
            )
        }

        init(title: String, id: String, backgroundColor: Color?, borderColor: Color) {
            self.title = title
            self.id = id
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
        }

        init?(
            purchaseInformation: PurchaseInformation,
            localization: CustomerCenterConfigData.Localization
        ) {
            if purchaseInformation.isLifetime {
                self = .lifetime(localization)
            } else if purchaseInformation.isExpired {
                self = .expired(localization)
            } else if purchaseInformation.isCancelled, purchaseInformation.isTrial {
                self = .cancelledTrial(localization)
            } else if purchaseInformation.isCancelled, purchaseInformation.store != .promotional {
                self = .cancelled(localization)
            } else if purchaseInformation.isTrial, purchaseInformation.pricePaid == .free {
                self = .freeTrial(localization)
            } else if purchaseInformation.renewalDate != nil || purchaseInformation.expirationDate != nil {
                self = .active(localization)
            } else {
                return nil
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchaseInformationCardView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            ScrollViewWithOSBackground {
                PurchaseInformationCardView(
                    purchaseInformation: .lifetime,
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .mock(
                        isCancelled: true,
                        renewalDate: nil
                    ),
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .mock(
                        isTrial: true,
                        isCancelled: true,
                        renewalDate: nil
                    ),
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .mock(pricePaid: .free, isTrial: true, isCancelled: false),
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .mock(isTrial: true, isCancelled: false),
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .mock(
                        isExpired: true,
                        expirationDate: PurchaseInformation.defaultExpirationDate,
                        renewalDate: nil
                    ),
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    title: "Product name",
                    storeTitle: "App Store",
                    accessibilityIdentifier: "accessibilityIdentifier",
                    badge: .active(CustomerCenterConfigData.default.localization),
                    additionalIcon: Image(systemName: "info.circle.fill"),
                    additionalInfo: "An error occurred while processing the refund request. Please try again.",
                    subtitle: "Renews 24 May for $19.99"
                )
                .padding([.leading, .trailing])
            }
            .preferredColorScheme(colorScheme)
        }
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
