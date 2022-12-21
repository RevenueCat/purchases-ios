//
//  Logger.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/28/22.
//

import Foundation

import RevenueCat

public final class Logger: ObservableObject {

    public struct Entry {
        public var level: LogLevel
        public var message: String
        public var id: UUID = .init()
    }

    @Published
    @MainActor
    public private(set) var messages: [Entry] = []

    @MainActor
    public func clearMessages() {
        self.messages.removeAll(keepingCapacity: false)
    }

    public init() {}

}

extension Logger {

    public var logHandler: (LogLevel, String) -> Void {
        return { level, message in
            DispatchQueue.main.async {
                self.messages.append(.init(level: level, message: message))
            }

            NSLog("\(level.description): \(message)")
        }
    }

}

extension Logger.Entry: Equatable, Identifiable {}
