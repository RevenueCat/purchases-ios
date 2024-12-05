//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallsStrings.swift
//
//  Created by Nacho Soto on 08/7/23.

import Foundation

// swiftlint:disable identifier_name

enum PaywallsStrings {

    case warming_up_eligibility_cache(products: Set<String>)
    case warming_up_images(imageURLs: Set<URL>)
    case error_prefetching_image(URL, Error)

    case caching_presented_paywall
    case clearing_presented_paywall

    // MARK: - Localization

    case empty_localization
    case looking_up_localization(preferred: [Locale], search: [Locale])
    case found_localization(Locale)
    case default_localization(localeIdentifier: String)
    case fallback_localization(localeIdentifier: String)

    // MARK: - Events

    case event_manager_initialized
    case event_manager_not_initialized_not_available
    case event_manager_failed_to_initialize(Error)

    case event_flush_already_in_progress
    case event_flush_with_empty_store
    case event_flush_starting(count: Int)
    case event_sync_failed(Error)
    case event_cannot_serialize
    case event_cannot_get_encoded_event
    case event_cannot_deserialize(Error)
    case event_missing_app_session_id

}

extension PaywallsStrings: LogMessage {

    var description: String {
        switch self {
        case let .warming_up_eligibility_cache(products):
            return "Warming up intro eligibility cache for \(products.count) products"

        case let .warming_up_images(imageURLs):
            return "Warming up paywall images cache: \(imageURLs)"

        case let .error_prefetching_image(url, error):
            return "Error pre-fetching paywall image '\(url)': \((error as NSError).description)"

        case .caching_presented_paywall:
            return "PurchasesOrchestrator: caching presented paywall"

        case .clearing_presented_paywall:
            return "PurchasesOrchestrator: clearing presented paywall"

        case .empty_localization:
            return "Looking up localization but found no strings"

        case let .looking_up_localization(preferred, search):
            return "Looking up localized configuration for \(preferred.map(\.identifier)), " +
            "searching for \(search.map(\.identifier))"

        case let .found_localization(locale):
            return "Found localized configuration for '\(locale.identifier)'"

        case let .default_localization(localeIdentifier):
            return "No localized configuration found, using default: \(localeIdentifier)"

        case let .fallback_localization(localeIdentifier):
            return "Failed looking up localization, using fallback: \(localeIdentifier)"

        // MARK: - Events

        case .event_manager_initialized:
            return "PaywallEventsManager initialized"

        case .event_manager_not_initialized_not_available:
            return "Won't initialize PaywallEventsManager: not available on current device."

        case let .event_manager_failed_to_initialize(error):
            return "PaywallEventsManager won't be initialized, event store failed to create " +
            "with error: \((error as NSError).localizedDescription)"

        case .event_flush_already_in_progress:
            return "Paywall event flushing already in progress. Skipping."

        case .event_flush_with_empty_store:
            return "Paywall event flushing requested with empty store."

        case let .event_flush_starting(count):
            return "Paywall event flush: posting \(count) events."

        case let .event_sync_failed(error):
            return "Paywall event flushing failed, will retry. Error: \((error as NSError).localizedDescription)"

        case .event_cannot_serialize:
            return "Couldn't serialize PaywallEvent to storage."

        case .event_cannot_get_encoded_event:
            return "Couldn't get encoded event from storage."

        case let .event_cannot_deserialize(error):
            return "Couldn't deserialize PaywallEvent from storage. Error: \((error as NSError).description)"

        case .event_missing_app_session_id:
            return "Event is missing the app session ID."
        }
    }

    var category: String { return "paywalls" }

}
