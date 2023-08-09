//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsFileHandler.swift
//
//  Created by Nacho Soto on 6/16/23.

import Foundation

protocol DiagnosticsFileHandlerType: AnyObject {

    func getEntries() async -> DiagnosticsEntries

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
actor DiagnosticsFileHandler: DiagnosticsFileHandlerType {

    private let fileHandler: FileHandler

    init?() {
        do {
            self.fileHandler = try .init(Self.diagnosticsFile)
        } catch {
            // TODO: more info and very content
            Logger.error(error.localizedDescription)
            return nil
        }
    }

    // TODO: method to delete file

    func getEntries() async -> DiagnosticsEntries {
        return []
//        return await self.fileHandler.readFile()
    }

}

// MARK: - Private

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension DiagnosticsFileHandler {

    static var diagnosticsFile: URL {
        return Self.documentsDirectory
            .appendingPathComponent("com.revenuecat")
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")
    }

    private static var documentsDirectory: URL {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return URL.documentsDirectory
        } else {
            return FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
        }

    }

}
