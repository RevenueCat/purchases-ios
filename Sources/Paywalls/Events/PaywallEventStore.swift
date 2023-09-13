//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventStore.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation

protocol PaywallEventStoreType {

    /// Stores `event` into the store.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func store(_ storedEvent: PaywallStoredEvent) async

    /// - Returns: the first `count` events from the store.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func fetch(_ count: Int) async -> [PaywallStoredEvent]

    /// Removes the first `count` events from the store.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func clear(_ count: Int) async

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
internal actor PaywallEventStore: PaywallEventStoreType {

    private let handler: FileHandlerType

    init(handler: FileHandlerType) {
        self.handler = handler
    }

    func store(_ storedEvent: PaywallStoredEvent) async {
        do {
            Logger.verbose(PaywallEventStoreStrings.storing_event(storedEvent.event))

            await self.handler.append(line: try PaywallEventSerializer.encode(storedEvent))
        } catch {
            Logger.error(PaywallEventStoreStrings.error_storing_event(error))
        }
    }

    func fetch(_ count: Int) async -> [PaywallStoredEvent] {
        assert(count > 0, "Invalid count: \(count)")

        do {
            return try await self.handler.readLines()
                .prefix(count)
                .compactMap { try? PaywallEventSerializer.decode($0) }
                .extractValues()
        } catch {
            Logger.error(PaywallEventStoreStrings.error_fetching_events(error))
            return []
        }
    }

    // - Note: If removing these `count` events fails, it will attempt to
    // remove the entire file. This ensures that the same events again aren't sent again.
    func clear(_ count: Int) async {
        assert(count > 0, "Invalid count: \(count)")

        do {
            try await self.handler.removeFirstLines(count)
        } catch {
            Logger.error(PaywallEventStoreStrings.error_removing_first_lines(count: count, error))

            do {
                try await self.handler.emptyFile()
            } catch {
                Logger.error(PaywallEventStoreStrings.error_emptying_file(error))
            }
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PaywallEventStore {

    static func createDefault(documentsDirectory: URL?) throws -> PaywallEventStore {
        let documentsDirectory = try documentsDirectory ?? Self.documentsDirectory
        let url = documentsDirectory
            .appendingPathComponent("revenuecat")
            .appendingPathComponent("paywall_event_store")

        Logger.verbose(PaywallEventStoreStrings.initializing(url))

        return try .init(handler: FileHandler(url))
    }

    private static var documentsDirectory: URL {
        get throws {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return URL.documentsDirectory
            } else {
                return try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            }
        }
    }

}

// MARK: - Messages

// swiftlint:disable identifier_name
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum PaywallEventStoreStrings {

    case initializing(URL)

    case storing_event(PaywallEvent)

    case error_storing_event(Error)
    case error_fetching_events(Error)
    case error_removing_first_lines(count: Int, Error)
    case error_emptying_file(Error)

}
// swiftlint:enable identifier_name

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEventStoreStrings: LogMessage {

    var description: String {
        switch self {
        case let .initializing(directory):
            return "Initializing PaywallEventStore: \(directory.absoluteString)"

        case let .storing_event(event):
            return "Storing event: \(event.debugDescription)"

        case let .error_storing_event(error):
            return "Error storing event: \((error as NSError).description)"

        case let .error_fetching_events(error):
            return "Error fetching events: \((error as NSError).description)"

        case let .error_removing_first_lines(count, error):
            return "Error removing first \(count) events: \((error as NSError).description)"

        case let .error_emptying_file(error):
            return "Error emptying file: \((error as NSError).description)"
        }
    }

    var category: String { return "paywall_event_store" }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEvent {

    var debugDescription: String {
        return "\(self)"
    }

}
