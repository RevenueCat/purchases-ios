//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Localization.swift
//
//  Created by Nacho Soto on 7/20/23.

import Foundation
import RevenueCat

enum Localization {

    /// - Returns: an appropriately short abbreviation for the given `unit`.
    static func abbreviatedUnitLocalizedString(
        for unit: SubscriptionPeriod.Unit,
        locale: Locale = .current
    ) -> String {
        let (full, brief, abbreviated) = self.unitLocalizedString(for: unit.calendarUnit, locale: locale)

        let options = [
            full,
            brief,
            abbreviated
        ]

        // Return the first option that matches the preferred length
        return self.unitAbbreviationLengthPriorities
            .lazy
            .compactMap { length in options.first { $0.count == length } }
            .first
        ?? options.last!
    }

    static func localizedDuration(
        for subscriptionPeriod: SubscriptionPeriod,
        locale: Locale = .current
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = locale
        formatter.allowedUnits = [subscriptionPeriod.unit.calendarUnit]
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.maximumUnitCount = 1

        return formatter.string(from: subscriptionPeriod.components) ?? ""
    }

    static func localized(
        packageType: PackageType,
        locale: Locale = .current
    ) -> String {
        guard let key = packageType.localizationKey else { return "" }

        func value(locale: Locale, default: String?) -> String {
            Self
                .localizedBundle(locale)
                .localizedString(forKey: key,
                                 value: `default`,
                                 table: nil)
        }

        // Returns the localized string
        return value(
            locale: locale,
            // Or defaults to english
            default: value(locale: Self.defaultLocale, default: nil)
        )
    }

    /// - Returns: the `Bundle` associated with the given locale if found
    /// Defaults to `Bundle.module`.
    ///
    /// `SwiftUI.Text` uses `EnvironmentValues.locale` and therefore
    /// can be mocked in tests.
    /// However, for views that load strings, this allows specifying a custom `Locale`.
    /// Example:
    /// ```swift
    /// let text = Localization
    ///    .localizedBundle(locale)
    ///    .localizedString(
    ///        forKey: "string",
    ///        value: nil,
    ///        table: nil
    ///    )
    /// ```
    static func localizedBundle(_ locale: Locale) -> Bundle {
        let containerBundle: Bundle = .module

        let preferredLocale = Bundle.preferredLocalizations(
            from: containerBundle.localizations,
            forPreferences: [locale.identifier]
        ).first

        let path = preferredLocale.flatMap { containerBundle.path(forResource: $0, ofType: "lproj") }
        return path.flatMap(Bundle.init(path:)) ?? containerBundle
    }

    /// - Returns: localized string for a discount. Example: "37% off"
    static func localized(
        discount: Double,
        locale: Locale
    ) -> String {
        assert(discount >= 0, "Invalid discount: \(discount)")

        let number = Int((discount * 100).rounded(.toNearestOrAwayFromZero))
        let format = self.localizedBundle(locale)
            .localizedString(forKey: "%d%% off", value: nil, table: nil)

        return String(format: format, number)
    }

}

// MARK: - Private

private extension Localization {

    static func unitLocalizedString(
        for unit: NSCalendar.Unit,
        locale: Locale = .current
    ) -> (full: String, brief: String, abbreviated: String) {
        var calendar: Calendar = .current
        calendar.locale = locale

        let date = Date()
        let value = 1
        let component = unit.component

        guard let sinceUnits = calendar.date(byAdding: component,
                                             value: value,
                                             to: date) else { return ("", "", "") }

        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.allowedUnits = [unit]

        func result(for style: DateComponentsFormatter.UnitsStyle) -> String {
            formatter.unitsStyle = style
            guard let string = formatter.string(from: date, to: sinceUnits) else { return "" }

            return string
                .replacingOccurrences(of: String(value), with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        return (full: result(for: .full),
                brief: result(for: .brief),
                abbreviated: result(for: .abbreviated))
    }

    /// The order in which unit abbreviations are preferred.
    static let unitAbbreviationLengthPriorities = [ 2, 3 ]

    /// For falling back in case language isn't localized.
    static let defaultLocale: Locale = .init(identifier: Self.defaultLocaleIdentifier)

    private static let defaultLocaleIdentifier: String = Locale.preferredLanguages.first ?? "en_US"

}

// MARK: - Extensions

private extension NSCalendar.Unit {

    var component: Calendar.Component {
        switch self {
        case .era: return .era
        case .year: return .year
        case .month: return .month
        case .day: return .day
        case .hour: return .hour
        case .minute: return .minute
        case .second: return .second
        case .weekday: return .weekday
        case .weekdayOrdinal: return .weekdayOrdinal
        case .quarter: return .quarter
        case .weekOfMonth: return .weekOfMonth
        case .weekOfYear: return .weekOfYear
        case .yearForWeekOfYear: return .yearForWeekOfYear
        case .nanosecond: return .nanosecond
        case .calendar: return .calendar
        case .timeZone: return .timeZone
        default: return .calendar
        }
    }
}

private extension SubscriptionPeriod.Unit {

    var calendarUnit: NSCalendar.Unit {
        switch self {
        case .day: return .day
        case .week: return .weekOfMonth
        case .month: return .month
        case .year: return .year
        }
    }

}

private extension SubscriptionPeriod {

    var components: DateComponents {
        switch self.unit {
        case .day:
            return DateComponents(day: self.value)
        case .week:
            return DateComponents(weekOfMonth: self.value)
        case .month:
            return DateComponents(month: self.value)
        case .year:
            return DateComponents(year: self.value)
        @unknown default:
            return .init()
        }
    }

}

private extension PackageType {

    var localizationKey: String? {
        let keyPrefix = "PackageType."

        switch self {
        case .annual: return "\(keyPrefix)annual"
        case .sixMonth: return "\(keyPrefix)sixMonth"
        case .threeMonth: return "\(keyPrefix)threeMonth"
        case .twoMonth: return "\(keyPrefix)twoMonth"
        case .monthly: return "\(keyPrefix)monthly"
        case .weekly: return "\(keyPrefix)weekly"
        case .lifetime: return "\(keyPrefix)lifetime"

        case .unknown, .custom:
            return nil
        }
    }

}
