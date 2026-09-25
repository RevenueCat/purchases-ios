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
import SwiftUI

enum Localization {

    /// - Returns: an appropriately short abbreviation for the given `unit`.
    static func abbreviatedUnitLocalizedString(
        for period: SubscriptionPeriod,
        locale: Locale = .current
    ) -> String {
        let options = self.unitLocalizedString(
            for: period,
            styles: Self.preferedAbbreviationStyles(for: locale),
            locale: locale
        )

        // Return the first option that matches the preferred length
        return self.unitAbbreviationLengthPriorities
            .lazy
            .compactMap { length in options.first { $0.count == length } }
            .first { _ in true } // See https://github.com/apple/swift/issues/55374
        // swiftlint:disable:next force_unwrapping
        ?? options.last!
    }

    /// - Returns: an appropriate unabbreviated description for the given `unit`.
    static func unitLocalizedString(
        for period: SubscriptionPeriod,
        locale: Locale = .current
    ) -> String {
        return self.unitLocalizedString(
            for: period,
            styles: Self.preferedFullStyles(for: locale),
            locale: locale
            // swiftlint:disable:next force_unwrapping
        ).first!
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
        locale: Locale,
        fallbackLocale: Locale = Self.fallbackLocale
    ) -> String? {
        guard let key = packageType.localizationKey else { return nil }

        func value(locale: Locale, fallback: String?) -> String {
            Self
                .localizedBundle(locale)
                .localizedString(forKey: key,
                                 value: fallback,
                                 table: nil)
        }

        // Returns the localized string
        return value(
            locale: locale,
            // Or falls back to first localization, and if unavailable, english
            fallback: value(locale: fallbackLocale, fallback: nil)
        )
    }

    /// - Returns: the `Bundle` associated with the given locale if found
    /// Defaults to `Bundle.revenueCatUI`.
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
        let containerBundle: Bundle = .revenueCatUI

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
        for period: SubscriptionPeriod,
        styles: [DateComponentsFormatter.UnitsStyle],
        locale: Locale = .current
    ) -> [String] {
        var calendar: Calendar = .current
        calendar.locale = locale

        let date = Date()
        let unit = period.unit.calendarUnit
        let component = unit.component
        let value = period.value

        guard let sinceUnits = calendar.date(byAdding: component,
                                             value: value,
                                             to: date) else {
            return styles.map { _ in "" }
        }

        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.allowedUnits = [unit]

        func result(for style: DateComponentsFormatter.UnitsStyle) -> String {
            formatter.unitsStyle = style
            guard let string = formatter.string(from: date, to: sinceUnits) else { return "" }

            if value == 1 {
                return string
                    .replacingOccurrences(of: String(value), with: "")
                    .trimmingCharacters(in: .whitespaces)
            } else {
                return string
                    .replacingOccurrences(of: " ", with: "")
            }
        }

        return styles.map(result(for:))
    }

    static func preferedAbbreviationStyles(for locale: Locale) -> [DateComponentsFormatter.UnitsStyle] {
        switch locale.languageCodeIdentifier {
        // Abbreviated does not fully work with Japanese
        case "ja": return [.brief]
        // Abbreviated is too short for German - Tag = T, Woche = Wo., Monat = M, Jahr = J
        // In Brief Tag = Tg., Woche = Wo., Monat = Mo., Jahr = J the Year is just J, which is not very clear
        // the full version is the best for German
        case "de": return [.full]
        default: return [.full, .brief, .abbreviated]
        }
    }

    static func preferedFullStyles(for locale: Locale) -> [DateComponentsFormatter.UnitsStyle] {
        // `.full` for all locales, but this allows customizing it
        // if needed, like `preferedAbbreviationStyles`.
        return [.full]
    }

    /// The order in which unit abbreviations are preferred.
    static let unitAbbreviationLengthPriorities = [ 2, 3 ]

    /// For falling back in case language isn't localized.
    static let fallbackLocale: Locale = .init(identifier: Self.fallbackLocaleIdentifier)

    private static let fallbackLocaleIdentifier: String = Locale.preferredLanguages.first ?? "en_US"

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
        @unknown default:
            Logger.warning("Unknown SubscriptionPeriod.Unit")
            return .year
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
            Logger.warning("Unknown SubscriptionPeriod")
            return .init()
        }
    }

}

private extension PackageType {

    var localizationKey: String? {
        switch self {
        case .annual: return "Annual"
        case .sixMonth: return "6 Month"
        case .threeMonth: return "3 Month"
        case .twoMonth: return "2 Month"
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        case .lifetime: return "Lifetime"

        case .unknown, .custom:
            return nil
        @unknown default:
            Logger.warning("Unknown localizationKey")
            return nil
        }
    }

}

private extension Locale {

    var languageCodeIdentifier: String? {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.languageCode?.identifier
        } else {
            return self.languageCode
        }
    }

    var regionCodeIdentifier: String? {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.region?.identifier
        } else {
            return self.regionCode
        }
    }

    /// The script of the locale, or the script implied by its region (e.g. `zh_TW` → `Hant`).
    var scriptCodeIdentifier: String? {
        let script: String?
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            script = self.language.script?.identifier
        } else {
            script = self.scriptCode
        }
        return script ?? self.regionCodeIdentifier.flatMap { Self.scriptsByRegion[$0] }
    }

    /// Scripts inferred from the region. Same values as `scriptByRegion` in purchases-android.
    static let scriptsByRegion: [String: String] = [
        "CN": "Hans",
        "SG": "Hans",
        "MY": "Hans",
        "TW": "Hant",
        "HK": "Hant",
        "MO": "Hant"
    ]

}

extension Locale {

    /// The SwiftUI `LayoutDirection` that matches this locale's character direction.
    /// Used to propagate RTL layout when a locale override is in effect but the system locale is LTR.
    var swiftUILayoutDirection: LayoutDirection {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
        } else {
            let code = self.languageCodeIdentifier ?? ""
            return Locale.characterDirection(forLanguage: code) == .rightToLeft
                ? .rightToLeft
                : .leftToRight
        }
    }

    /// Selects the best-matching locale from `availableLocales` given `preferredLocales`.
    ///
    /// Uses the first preferred locale whose language is available, and returns, in this order:
    /// 1. The locale with the same language, script and region. `en-GB` and `en_GB` are the same locale.
    /// 2. The first locale with the same language and script, e.g. `zh_Hant` for `zh-Hant-TW`.
    /// 3. The first locale with the same language.
    ///
    /// Candidates are sorted by identifier, so the result doesn't depend on the order of `availableLocales`
    /// (which usually comes from a `Dictionary`). This mirrors `getBestMatch` in purchases-android.
    /// Returns `nil` if no language match exists for any preferred locale.
    static func selectPreferredLocale(from availableLocales: [Locale],
                                      preferredLocales: [Locale]) -> Locale? {
        let candidates = availableLocales.sorted { $0.identifier < $1.identifier }

        for preferred in preferredLocales {
            let languageMatches = candidates.filter {
                $0.languageCodeIdentifier == preferred.languageCodeIdentifier
            }
            guard let languageMatch = languageMatches.first else { continue }

            let preferredScript = preferred.scriptCodeIdentifier

            if let exactMatch = languageMatches.first(where: {
                $0.regionCodeIdentifier == preferred.regionCodeIdentifier &&
                $0.scriptCodeIdentifier == preferredScript
            }) {
                return exactMatch
            }

            if let preferredScript,
               let scriptMatch = languageMatches.first(where: { $0.scriptCodeIdentifier == preferredScript }) {
                return scriptMatch
            }

            return languageMatch
        }
        return nil
    }

}
