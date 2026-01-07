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

    func updateDelegate(_ delegate: DiagnosticsFileHandlerDelegate?) async

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

protocol DiagnosticsFileHandlerDelegate: AnyObject, Sendable {
    func onFileSizeIncreasedBeyondAutomaticSyncLimit() async
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
actor DiagnosticsFileHandler: DiagnosticsFileHandlerType {

    private weak var delegate: DiagnosticsFileHandlerDelegate?

    private let fileHandler: FileHandlerType

    init?() {
        Self.deleteOldDiagnosticsFileIfExists()

        guard let diagnosticsFileURL = Self.diagnosticsFileURL else {
            Logger.error(Strings.diagnostics.failed_to_create_diagnostics_file_url)
            return nil
        }

        do {
            self.fileHandler = try FileHandler(diagnosticsFileURL)
        } catch {
            Logger.error(Strings.diagnostics.failed_to_initialize_file_handler(error: error))
            return nil
        }
    }

    init(_ fileHandler: FileHandlerType) {
        self.fileHandler = fileHandler
    }

    func updateDelegate(_ delegate: DiagnosticsFileHandlerDelegate?) async {
        self.delegate = delegate
    }

    func appendEvent(diagnosticsEvent: DiagnosticsEvent) async {
        guard let jsonString = try? diagnosticsEvent.encodedJSON else {
            Logger.error(Strings.diagnostics.failed_to_serialize_diagnostic_event)
            return
        }

        do {
            try await self.fileHandler.append(line: jsonString)
        } catch {
            Logger.error(Strings.diagnostics.failed_to_store_diagnostics_event(error: error))
        }

        if await self.isDiagnosticsFileBigEnoughToSync() {
            await self.delegate?.onFileSizeIncreasedBeyondAutomaticSyncLimit()
        }
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
    private static let minFileSizeEnoughToSyncInKb: Double = 200
}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsFileHandler {

    static var diagnosticsFileURL: URL? {
        guard let baseURL = DirectoryHelper.baseUrl(for: .applicationSupport) else {
            return nil
        }
        return baseURL
            .appendingPathComponent("diagnostics")
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")
    }

    // TODO: check if we should perform this every time.
    /*
     It might cause the 'X would like access to the Documents folder' on new installations on macOS (unsandboxed).
     We can't however check for permissions beforehand, since that will also trigger the popup
     */

    /*
     We were previously storing the diagnostics file in the Documents directory
     which may end up in the Files app or the user's Documents directory on macOS.
     */
    private static func deleteOldDiagnosticsFileIfExists() {
        let oldFileURL: URL
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            oldFileURL = URL.documentsDirectory
        } else {
            guard let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first else {
                return
            }
            oldFileURL = documentsURL
        }

        let parentDirectoryName = "com.revenuecat"

        let oldDiagnosticsFile = oldFileURL
            .appendingPathComponent(parentDirectoryName)
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")

        guard FileManager.default.fileExists(atPath: oldDiagnosticsFile.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: oldDiagnosticsFile)

            // Also delete the parent folder if it's empty
            let parentFolder = oldFileURL.appendingPathComponent(parentDirectoryName)
            let contents = try? FileManager.default.contentsOfDirectory(atPath: parentFolder.path)
            if let contents = contents, contents.isEmpty {
                try? FileManager.default.removeItem(at: parentFolder)
            }
        } catch {
            Logger.error(Strings.diagnostics.failed_to_delete_old_diagnostics_file(error: error))
        }
    }

    private func isDiagnosticsFileBigEnoughToSync() async -> Bool {
        do {
            return try await self.fileHandler.fileSizeInKB() > Self.minFileSizeEnoughToSyncInKb
        } catch {
            Logger.error(Strings.diagnostics.failed_check_diagnostics_size(error: error))
            return true
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
