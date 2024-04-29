//
//  Logging.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-04-17.
//

import Foundation

import os.log

struct Logging {

    static let shared = Logging()

    func logger(category: String) -> Logger {
        return loggers[category,
                       default:Logger(subsystem: Bundle.main.bundleIdentifier!,
                                      category: category)]
    }

    private init() {}

    private let loggers = [String: Logger]()

}
