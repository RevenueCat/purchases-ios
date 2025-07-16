//
//  CustomerCenter+PreferenceKeys.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 24/3/25.
//

import RevenueCat
import SwiftUI

#if os(iOS)

// MARK: - CustomerCenterView Extension

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterView {

    // MARK: - Preference Keys

    struct RestoreStartedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<Void>?
        static func reduce(value: inout UniqueWrapper<Void>?, nextValue: () -> UniqueWrapper<Void>?) {
            value = nextValue() ?? value
        }
    }

    struct RestoreFailedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<NSError>?
        static func reduce(value: inout UniqueWrapper<NSError>?, nextValue: () -> UniqueWrapper<NSError>?) {
            value = nextValue() ?? value
        }
    }

    struct RestoreCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<CustomerInfo>?
        static func reduce(value: inout UniqueWrapper<CustomerInfo>?, nextValue: () -> UniqueWrapper<CustomerInfo>?) {
            value = nextValue() ?? value
        }
    }

    struct ShowingManageSubscriptionsPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<Void>?
        static func reduce(value: inout UniqueWrapper<Void>?, nextValue: () -> UniqueWrapper<Void>?) {
            value = nextValue() ?? value
        }
    }

    struct RefundRequestStartedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<String>?
        static func reduce(value: inout UniqueWrapper<String>?, nextValue: () -> UniqueWrapper<String>?) {
            value = nextValue() ?? value
        }
    }

    struct RefundRequestCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<(String, RefundRequestStatus)>?
        static func reduce(value: inout UniqueWrapper<(String, RefundRequestStatus)>?,
                           nextValue: () -> UniqueWrapper<(String, RefundRequestStatus)>?) {
            value = nextValue() ?? value
        }
    }

    struct FeedbackSurveyCompletedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<String>?
        static func reduce(value: inout UniqueWrapper<String>?, nextValue: () -> UniqueWrapper<String>?) {
            value = nextValue() ?? value
        }
    }

    struct ManagementOptionSelectedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<CustomerCenterActionable>?
        static func reduce(value: inout UniqueWrapper<CustomerCenterActionable>?,
                           nextValue: () -> UniqueWrapper<CustomerCenterActionable>?) {
            value = nextValue() ?? value
        }
    }

    struct PromotionalOfferSuccessPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<Void>?
        static func reduce(value: inout UniqueWrapper<Void>?,
                           nextValue: () -> UniqueWrapper<Void>?) {
            value = nextValue() ?? value
        }
    }

    struct ChangePlansSelectedPreferenceKey: PreferenceKey {
        static var defaultValue: UniqueWrapper<String?>?
        static func reduce(value: inout UniqueWrapper<String?>?,
                           nextValue: () -> UniqueWrapper<String?>?) {
            value = nextValue() ?? value
        }
    }
}

#endif
