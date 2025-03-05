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
//  Created by Cesar de la Vega on 8/4/24.

import Foundation

protocol DiagnosticsFileHandlerType: Sendable {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func getEntries() async -> [DiagnosticsEvent?]

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func appendEvent(diagnosticsEvent: DiagnosticsEvent) async

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func cleanSentDiagnostics(diagnosticsSentCount: Int) async

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func emptyDiagnosticsFile() async

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func isDiagnosticsFileTooBig() async -> Bool

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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

    init(_ fileHandler: FileHandler) {
        self.fileHandler = fileHandler
    }

    func appendEvent(diagnosticsEvent: DiagnosticsEvent) async {
        guard let jsonString = try? diagnosticsEvent.encodedJSON else {
            Logger.error("Failed to serialize diagnostics event to JSON")
            return
        }

        await self.fileHandler.append(line: jsonString)
    }

    func getEntries() async -> [DiagnosticsEvent?] {
        do {
            return try await self.fileHandler.readLines()
                .map { try? JSONDecoder.default.decode(jsonData: $0.asData) }
                .extractValues()
        } catch {
            Logger.error(Strings.diagnostics.error_fetching_events(error: error))
            return []
        }
    }

    func cleanSentDiagnostics(diagnosticsSentCount: Int) async {
        guard diagnosticsSentCount > 0 else {
            Logger.error(Strings.diagnostics.invalid_sent_diagnostics_count(count: diagnosticsSentCount))
            return
        }

        do {
            try await self.fileHandler.removeFirstLines(diagnosticsSentCount)
        } catch {
            Logger.error(Strings.diagnostics.failed_to_clean_sent_diagnostics(error: error))
        }
    }

    func emptyDiagnosticsFile() async {
        do {
            try await self.fileHandler.emptyFile()
        } catch {
            Logger.error(Strings.diagnostics.failed_to_empty_diagnostics_file(error: error))
        }
    }

    func isDiagnosticsFileTooBig() async -> Bool {
        do {
            return try await self.fileHandler.fileSizeInKB() > Self.maxFileSizeInKb
        } catch {
            Logger.error(Strings.diagnostics.failed_check_diagnostics_size(error: error))
            return true
        }
    }

    private static let maxFileSizeInKb: Double = 500
}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
        do {
            guard let data = line.data(using: .utf8) else { return nil }
            return try JSONDecoder.default.decode(DiagnosticsEvent.self, from: data)
        } catch {
            return nil
        }
    }

}
