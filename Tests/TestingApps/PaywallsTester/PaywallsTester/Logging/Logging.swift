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
    
    private init() {}
    
    func logger(category: String) -> Logger {
        return Logger(subsystem: Bundle.main.bundleIdentifier!,
                      category: category)
    }
}
