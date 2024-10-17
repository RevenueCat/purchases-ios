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

protocol FeatureEventStoreType: Sendable {

    /// Stores `event` into the store.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func store<T: FeatureEvent>(_ storedEvent: StoredFeatureEvent<T>) async

    /// - Returns: the first `count` events from the store.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func fetch(_ count: Int) async -> [AnyStoredFeatureEventType]

    /// Removes the first `count` events from the store.
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func clear(_ count: Int) async

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
internal actor FeatureEventStore: FeatureEventStoreType {

    private let handler: FileHandlerType

    init(handler: FileHandlerType) {
        self.handler = handler
    }

    func store<T: FeatureEvent>(_ storedEvent: StoredFeatureEvent<T>) async {
        do {
            Logger.verbose(PaywallEventStoreStrings.storing_event(storedEvent.event))

            await self.handler.append(line: try FeatureEventSerializer.encode(storedEvent))
        } catch {
            Logger.error(PaywallEventStoreStrings.error_storing_event(error))
        }
    }

    func fetch(_ count: Int) async -> [AnyStoredFeatureEventType] {
        assert(count > 0, "Invalid count: \(count)")

        do {
            return try await self.handler.readLines()
                .prefix(count)
                .compactMap {
                    try? FeatureEventSerializer.decode($0)
                }
                .extractValues()
        } catch {
            Logger.error(PaywallEventStoreStrings.error_fetching_events(error))
            return []
        }
    }

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
extension FeatureEventStore {

    static func createDefault(
        applicationSupportDirectory: URL?,
        documentsDirectory: URL? = nil
    ) throws -> FeatureEventStore {
        let url = Self.url(in: try applicationSupportDirectory ?? Self.applicationSupportDirectory)
        Logger.verbose(PaywallEventStoreStrings.initializing(url))

        let documentsDirectory = try documentsDirectory ?? Self.documentsDirectory
        Self.removeLegacyDirectoryIfExists(documentsDirectory)

        return try .init(handler: FileHandler(url))
    }

    private static func revenueCatFolder(in container: URL) -> URL {
        return container.appendingPathComponent("revenuecat")
    }

    private static func url(in container: URL) -> URL {
        return self.revenueCatFolder(in: container).appendingPathComponent("paywall_event_store")
    }

    private static func removeLegacyDirectoryIfExists(_ documentsDirectory: URL) {
        let url = Self.revenueCatFolder(in: documentsDirectory)
        guard Self.fileManager.fileExists(atPath: url.relativePath) else { return }

        Logger.debug(PaywallEventStoreStrings.removing_old_documents_store(url))

        do {
            try Self.fileManager.removeItem(at: url)
        } catch {
            Logger.error(PaywallEventStoreStrings.error_removing_old_documents_store(error))
        }
    }

    // See https://nemecek.be/blog/57/making-files-from-your-app-available-in-the-ios-files-app
    // We don't want to store events in the documents directory in case app makes their documents
    // accessible via the Files app.
    private static var applicationSupportDirectory: URL {
        get throws {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return URL.applicationSupportDirectory
            } else {
                return try Self.fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            }
        }
    }

    private static var documentsDirectory: URL {
        get throws {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
                return URL.documentsDirectory
            } else {
                return try Self.fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                )
            }
        }
    }

    private static var fileManager: FileManager {
        return .default
    }

}

// MARK: - Messages

// swiftlint:disable identifier_name
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum PaywallEventStoreStrings {

    case initializing(URL)

    case removing_old_documents_store(URL)
    case error_removing_old_documents_store(Error)

    case storing_event(any FeatureEvent)

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

        case let .removing_old_documents_store(url):
            return "Removing old store: \(url)"

        case let .error_removing_old_documents_store(error):
            return "Failed removing old store: \((error as NSError).description)"

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
private extension FeatureEvent {

    var debugDescription: String {
        return "\(self)"
    }

}
