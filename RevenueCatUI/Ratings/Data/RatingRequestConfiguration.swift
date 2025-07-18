//
//  RatingRequestConfiguration.swift
//
//  Created by RevenueCat on 1/2/25.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct RatingRequestConfiguration {

    public let screenTitle: String
    public let primaryButtonTitle: String
    public let secondaryButtonTitle: String
    public let memojis: [Image]
    public let primaryButtonAction: (() -> Void)?
    public let secondaryButtonAction: (() -> Void)?

    public init(
        screenTitle: String = "Rate Our App",
        primaryButtonTitle: String = "Rate on App Store",
        secondaryButtonTitle: String = "Maybe Later",
        memojis: [Image] = Self.defaultMemojis,
        primaryButtonAction: (() -> Void)? = nil,
        secondaryButtonAction: (() -> Void)? = nil
    ) {
        self.screenTitle = screenTitle
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.memojis = memojis
        self.primaryButtonAction = primaryButtonAction
        self.secondaryButtonAction = secondaryButtonAction
    }

    public static let `default` = RatingRequestConfiguration()

    public static let defaultMemojis: [Image] = [
        Image(systemName: "person.circle.fill"),
        Image(systemName: "person.2.circle.fill"),
        Image(systemName: "person.3.circle.fill"),
        Image(systemName: "person.crop.circle.fill"),
        Image(systemName: "person.crop.circle.fill.badge.checkmark")
    ]
}
