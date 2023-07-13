//
// StoreProductDiscount+Localization.swift
//  
//
//  Created by Nacho Soto on 7/12/23.
//

import Foundation
import RevenueCat

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension StoreProductDiscount {

    var localizedDuration: String {
        return self.subscriptionPeriod.localizedDuration
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension SubscriptionPeriod {

    var localizedDuration: String {
        return self.localizedDuration(for: .current)
    }

    func localizedDuration(for locale: Locale) -> String {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = locale
        formatter.allowedUnits = [self.unit.calendarUnit]
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.maximumUnitCount = 1

        return formatter.string(from: self.components) ?? ""
    }

    private var components: DateComponents {
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
