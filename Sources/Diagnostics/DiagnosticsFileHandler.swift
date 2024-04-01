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

    func getEntries() async -> [DiagnosticsEvent]
    func appendEvent(diagnosticsEvent: DiagnosticsEvent) async
    func cleanSentDiagnostics(diagnosticsSentCount: Int) async
    func deleteDiagnosticsFile() async
    
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
actor DiagnosticsFileHandler: DiagnosticsFileHandlerType {

    private let fileHandler: FileHandler

    init?() {
        do {
            self.fileHandler = try .init(Self.diagnosticsFile)
        } catch {
            Logger.error("Initialization error: \(error.localizedDescription)")
            return nil
        }
    }

    func appendEvent(diagnosticsEvent: DiagnosticsEvent) async {
        guard let jsonString = diagnosticsEvent.toJSONString() else {
            Logger.error("Failed to serialize diagnostics event to JSON")
            return
        }

        await fileHandler.append(line: jsonString)
    }

    func getEntries() async -> [DiagnosticsEvent] {
        var entries: [DiagnosticsEvent] = []

        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            do {
                for try await line in try await fileHandler.readLines() {
                    if let event = decodeDiagnosticsEvent(from: line) {
                        entries.append(event)
                    }
                }
            } catch {
                Logger.error("Failed to read lines from file: \(error.localizedDescription)")
            }
        } else {
            do {
                let data = try await fileHandler.readFile()
                let content = String(decoding: data, as: UTF8.self)
                content.split(separator: "\n").forEach { line in
                    if let event = decodeDiagnosticsEvent(from: String(line)) {
                        entries.append(event)
                    }
                }
            } catch {
                Logger.error("Failed to read file content: \(error.localizedDescription)")
            }
        }

        return entries
    }

    func cleanSentDiagnostics(diagnosticsSentCount: Int) async {
        guard diagnosticsSentCount > 0 else {
            Logger.error("Invalid sent diagnostics count: \(diagnosticsSentCount)")
            return
        }

        do {
            try await fileHandler.removeFirstLines(diagnosticsSentCount)
        } catch {
            Logger.error("Failed to clean sent diagnostics: \(error.localizedDescription)")
        }
    }

    func deleteDiagnosticsFile() async {
        // TODO
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

    private func decodeDiagnosticsEvent(from line: String) -> DiagnosticsEvent? {
        guard let data = line.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DiagnosticsEvent.self, from: data)
    }
}
