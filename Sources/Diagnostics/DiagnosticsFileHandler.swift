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
    private var diagnosticsFileExistedOnInit = false
    private var didDeleteOldDiagnosticsFile = false
    private let fileManager = FileManager.default

    init?() {
        guard let diagnosticsFileURL = Self.diagnosticsFileURL else {
            Logger.error(Strings.diagnostics.failed_to_create_diagnostics_file_url)
            return nil
        }

        diagnosticsFileExistedOnInit = fileManager.fileExists(atPath: diagnosticsFileURL.path)

        do {
            self.fileHandler = try FileHandler(diagnosticsFileURL)
        } catch {
            Logger.error(Strings.diagnostics.failed_to_initialize_file_handler(error: error))
            return nil
        }
    }

    #if DEBUG
    /// Only used in testing. 
    init(_ fileHandler: FileHandlerType) {
        assert(!(fileHandler is FileHandler), "This init is only meant for testing. Use the regular init instead.")
        self.fileHandler = fileHandler
    }
    #endif

    func updateDelegate(_ delegate: DiagnosticsFileHandlerDelegate?) async {
        self.delegate = delegate
    }

    func appendEvent(diagnosticsEvent: DiagnosticsEvent) async {
        var jsonString: String?
        do {
            jsonString = try diagnosticsEvent.encodedJSON
        } catch {
            Logger.error(Strings.diagnostics.failed_to_serialize_diagnostic_event(error: error))
        }

        guard let jsonString else { return }

        do {
            deleteOldDiagnosticsFileIfNeeded()

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
        guard let baseURL = DirectoryHelper.baseUrl(for: .persistence) else {
            return nil
        }
        return baseURL
            .appendingPathComponent("diagnostics", isDirectory: true)
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")
    }

    private static var oldDiagnosticsDirectoryURL: URL? {
        let documentsDirectoryURL: URL?
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            documentsDirectoryURL = URL.documentsDirectory
        } else {
            documentsDirectoryURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        }

        return documentsDirectoryURL?.appendingPathComponent("com.revenuecat", isDirectory: true)
    }

    private static var oldDiagnosticsFileURL: URL? {
        oldDiagnosticsDirectoryURL?
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")
    }

    /*
     We were previously storing the diagnostics file in the Documents directory
     which may end up in the Files app or the user's Documents directory on macOS.
     We'll try to delete it if the new file did not exist yet.
     */
    private func deleteOldDiagnosticsFileIfNeeded() {
        guard !diagnosticsFileExistedOnInit && !didDeleteOldDiagnosticsFile else { return }

        guard let oldDiagnosticsDirectoryURL = Self.oldDiagnosticsDirectoryURL,
                let oldDiagnosticsFileURL = Self.oldDiagnosticsFileURL,
                FileManager.default.fileExists(atPath: oldDiagnosticsFileURL.path)
        else {
            return
        }

        do {
            try FileManager.default.removeItem(at: oldDiagnosticsFileURL)

            let contents = try? FileManager.default.contentsOfDirectory(atPath: oldDiagnosticsDirectoryURL.path)
            if let contents = contents, contents.isEmpty {
                try? FileManager.default.removeItem(at: oldDiagnosticsDirectoryURL)
            }
            didDeleteOldDiagnosticsFile = true
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
