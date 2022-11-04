//
//  Logger.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/28/22.
//

import Foundation

import RevenueCat

final class Logger: ObservableObject {

    struct Entry {
        var level: LogLevel
        var message: String
        var id: UUID = .init()
    }

    @Published
    @MainActor
    var messages: [Entry] = []

    init() {}

}

extension Logger {

    var logHandler: (LogLevel, String) -> Void {
        return { level, message in
            DispatchQueue.main.async {
                self.messages.append(.init(level: level, message: message))
            }

            NSLog("\(level.description): \(message)")
        }
    }

}

extension Logger.Entry: Equatable, Identifiable {}
