//
//  LiveJSONPaywallView.swift
//  PaywallsTester
//
//  Renders a paywall from a JSON file on disk and re-renders it whenever that
//  file changes, so paywall JSON can be iterated on without rebuilding.
//
//  Window size conditions read `\.paywallWindowSize`, which is the paywall's
//  rendered container bounds (see ScreenCondition.swift) — so resizing the
//  Catalyst window or the iPad Split View pane drives the responsive rules.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@_spi(Internal) import RevenueCat
#if DEBUG
@_spi(Internal) @testable import RevenueCatUI
#else
@_spi(Internal) import RevenueCatUI
#endif

#if DEBUG && !os(tvOS) && !os(watchOS)

// MARK: - Loader

/// Watches a directory of paywall JSON files and rebuilds an `Offering` whenever
/// the selected file changes on disk.
///
/// Change detection is a modification-date/size poll rather than a `DispatchSource`
/// vnode watch: an agent or editor that writes atomically replaces the inode, which
/// silently detaches a vnode source, and an in-place write to a file does not fire
/// the *directory*'s vnode event. Polling catches both.
@available(iOS 15.0, macOS 13.0, *)
@MainActor
final class LivePaywallJSONLoader: ObservableObject {

    struct Status {
        var lastLoaded: Date?
        var reloadCount: Int = 0
        var errorMessage: String?
    }

    private static let pollInterval: TimeInterval = 0.3
    private static let directoryRescanInterval: TimeInterval = 2.0
    private static let bookmarkDefaultsKey = "LivePaywallJSONLoader.directoryBookmark"
    private static let offeringIdentifier = "live-json"

    @Published private(set) var offering: Offering?
    @Published private(set) var status = Status()
    @Published private(set) var directoryURL: URL?
    @Published private(set) var availableFileNames: [String] = []

    @Published var selectedFileName: String? {
        didSet {
            guard oldValue != self.selectedFileName else { return }
            self.lastSignature = nil
            self.reloadSelectedFile()
        }
    }

    /// (modification date, size) of the file as of the last successful poll.
    private var lastSignature: (Date, Int)?
    private var pollTimer: Timer?
    private var lastDirectoryScan: Date = .distantPast
    private var securityScopedURL: URL?

    init() {
        self.adoptDirectory(Self.resolveInitialDirectory())
        self.startPolling()
    }

    deinit {
        // `stopAccessing` is the matching call to `startAccessing` in `adoptDirectory`.
        MainActor.assumeIsolated {
            self.securityScopedURL?.stopAccessingSecurityScopedResource()
            self.pollTimer?.invalidate()
        }
    }

    // MARK: Directory selection

    /// Resolution order: an explicit `LIVE_PAYWALL_DIR` override, then the host's
    /// `~/rc/paywall-live` when running in the simulator, then a folder the user
    /// previously granted access to through the importer.
    private static func resolveInitialDirectory() -> URL? {
        let environment = ProcessInfo.processInfo.environment

        if let override = environment["LIVE_PAYWALL_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }

        if let hostHome = environment["SIMULATOR_HOST_HOME"], !hostHome.isEmpty {
            return URL(fileURLWithPath: hostHome, isDirectory: true)
                .appendingPathComponent("rc/paywall-live", isDirectory: true)
        }

        return Self.resolveBookmarkedDirectory()
    }

    private static func resolveBookmarkedDirectory() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkDefaultsKey) else { return nil }

        var isStale = false
        let url = try? URL(
            resolvingBookmarkData: data,
            options: Self.bookmarkResolutionOptions,
            bookmarkDataIsStale: &isStale
        )
        return url
    }

    #if targetEnvironment(macCatalyst)
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
    #else
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = []
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = []
    #endif

    /// Called by the folder importer. Persists a bookmark so the grant survives relaunch.
    func selectDirectory(_ url: URL) {
        if let data = try? url.bookmarkData(
            options: Self.bookmarkCreationOptions,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            UserDefaults.standard.set(data, forKey: Self.bookmarkDefaultsKey)
        }
        self.adoptDirectory(url)
    }

    private func adoptDirectory(_ url: URL?) {
        self.securityScopedURL?.stopAccessingSecurityScopedResource()
        self.securityScopedURL = nil

        guard let url else {
            self.directoryURL = nil
            return
        }

        if url.startAccessingSecurityScopedResource() {
            self.securityScopedURL = url
        }

        self.directoryURL = url
        self.lastSignature = nil
        self.rescanDirectory(force: true)
        self.reloadSelectedFile()
    }

    // MARK: Polling

    private func startPolling() {
        let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.pollTimer = timer
    }

    private func tick() {
        if Date().timeIntervalSince(self.lastDirectoryScan) >= Self.directoryRescanInterval {
            self.rescanDirectory(force: false)
        }

        guard let url = self.selectedFileURL, let signature = Self.signature(of: url) else { return }

        if let last = self.lastSignature, last.0 == signature.0, last.1 == signature.1 {
            return
        }
        self.lastSignature = signature
        self.reloadSelectedFile()
    }

    private static func signature(of url: URL) -> (Date, Int)? {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
              let date = values.contentModificationDate else { return nil }
        return (date, values.fileSize ?? 0)
    }

    private func rescanDirectory(force: Bool) {
        self.lastDirectoryScan = Date()

        guard let directoryURL else {
            self.availableFileNames = []
            return
        }

        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directoryURL.path)) ?? []
        let names = contents
            .filter { $0.hasSuffix(".json") && !$0.hasSuffix(Self.localizationsSuffix) }
            .sorted()

        guard force || names != self.availableFileNames else { return }
        self.availableFileNames = names

        if let selectedFileName, names.contains(selectedFileName) { return }
        // `selectedFileName`'s observer reloads; prefer `live.json` by convention.
        self.selectedFileName = names.contains("live.json") ? "live.json" : names.first
    }

    var selectedFileURL: URL? {
        guard let directoryURL, let selectedFileName else { return nil }
        return directoryURL.appendingPathComponent(selectedFileName)
    }

    // MARK: Loading

    func reloadNow() {
        self.lastSignature = nil
        self.reloadSelectedFile()
    }

    private func reloadSelectedFile() {
        guard let url = self.selectedFileURL else {
            self.offering = nil
            self.status.errorMessage = self.directoryURL == nil
                ? "No folder selected."
                : "No .json files in \(self.directoryURL?.lastPathComponent ?? "folder")."
            return
        }

        do {
            self.offering = try Self.makeOffering(at: url)
            self.status.errorMessage = nil
            self.status.lastLoaded = Date()
            self.status.reloadCount += 1
        } catch {
            // Keep the last good render on screen so a half-written file doesn't blank it.
            self.status.errorMessage = Self.describe(error)
        }
    }

    // MARK: Decoding

    private static func documentObject(at url: URL) throws -> [String: Any] {
        let parsed = try JSONSerialization.jsonObject(with: try Data(contentsOf: url))
        guard var object = parsed as? [String: Any] else { return [:] }

        if url.lastPathComponent.hasSuffix(Self.componentsSuffix) {
            let prefix = url.lastPathComponent.dropLast(Self.componentsSuffix.count)
            let sibling = url.deletingLastPathComponent()
                .appendingPathComponent("\(prefix)\(Self.localizationsSuffix)")
            let localizations = (try? Data(contentsOf: sibling))
                .flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]

            object = [
                "components_config": object,
                "components_localizations": localizations?["components_localizations"] ?? [:],
                "default_locale": localizations?["default_locale"] ?? "en_US"
            ]
        }

        // A split export carries none of these, and their absence makes the SDK fall
        // back to the default template instead of reporting a decode failure.
        object["template_name"] = object["template_name"] ?? "components"
        object["asset_base_url"] = object["asset_base_url"] ?? "https://assets.pawwalls.com"
        object["revision"] = object["revision"] ?? 1
        return object
    }

    static let componentsSuffix = "-components.json"
    static let localizationsSuffix = "-localizations.json"

    /// Accepts three shapes:
    ///  - a whole `PaywallComponentsData` document,
    ///  - the `{ "paywall": ..., "ui_config": ... }` envelope the render harness uses,
    ///  - a mafdet export, which splits the document into `<id>-components.json`
    ///    (the `components_config` value) and `<id>-localizations.json` (the
    ///    `default_locale` and `components_localizations`). Neither half loads on
    ///    its own, so the sibling is read and the two are recombined here.
    private static func makeOffering(at url: URL) throws -> Offering {
        var topLevel = try Self.documentObject(at: url)

        let paywallObject: [String: Any]
        let uiConfigObject: [String: Any]?

        if let wrapped = topLevel["paywall"] as? [String: Any] {
            paywallObject = wrapped
            uiConfigObject = topLevel["ui_config"] as? [String: Any]
        } else {
            paywallObject = topLevel
            uiConfigObject = topLevel["ui_config"] as? [String: Any]
        }

        let componentsData = try Self.decodePaywallComponents(paywallObject)
        let uiConfig = try Self.decodeUIConfig(uiConfigObject)

        return Offering(
            identifier: Self.offeringIdentifier,
            serverDescription: "Live JSON",
            metadata: [:],
            paywallComponents: .init(uiConfig: uiConfig, data: componentsData),
            availablePackages: Self.packages(for: Self.collectPackageIDs(paywallObject)),
            webCheckoutUrl: nil
        )
    }

    private static func decodePaywallComponents(_ object: [String: Any]) throws -> PaywallComponentsData {
        var object = object
        // The dashboard emits a flat list here; iOS expects it keyed by store.
        if let zeroDecimalCountries = object["zero_decimal_place_countries"] as? [String] {
            object["zero_decimal_place_countries"] = ["apple": zeroDecimalCountries]
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(
            PaywallComponentsData.self,
            from: try JSONSerialization.data(withJSONObject: object)
        )
    }

    private static func decodeUIConfig(_ object: [String: Any]?) throws -> UIConfig {
        guard let object, !object.isEmpty else { return PreviewUIConfig.make() }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UIConfig.self, from: try JSONSerialization.data(withJSONObject: object))
    }

    /// Every distinct `package_id` referenced anywhere in the component tree, in
    /// document order, so package components resolve against real packages.
    private static func collectPackageIDs(_ object: [String: Any]) -> [String] {
        var ids = [String]()
        var seen = Set<String>()

        func visit(_ value: Any) {
            if let dictionary = value as? [String: Any] {
                if let packageID = dictionary["package_id"] as? String,
                   !packageID.isEmpty,
                   seen.insert(packageID).inserted {
                    ids.append(packageID)
                }
                dictionary.values.forEach(visit)
            } else if let array = value as? [Any] {
                array.forEach(visit)
            }
        }

        visit(object)
        return ids
    }

    private static let templatePackages: [Package] = [
        TestData.weeklyPackage,
        TestData.monthlyPackage,
        TestData.threeMonthPackage,
        TestData.sixMonthPackage,
        TestData.annualPackage,
        TestData.lifetimePackage
    ]

    private static func packages(for identifiers: [String]) -> [Package] {
        guard !identifiers.isEmpty else { return Self.templatePackages }

        return identifiers.map { identifier in
            let template = Self.template(matching: identifier)
            guard template.identifier != identifier else { return template }

            return Package(
                identifier: identifier,
                packageType: template.packageType,
                storeProduct: template.storeProduct,
                offeringIdentifier: Self.offeringIdentifier,
                webCheckoutUrl: nil
            )
        }
    }

    private static func template(matching identifier: String) -> Package {
        let lowercased = identifier.lowercased()

        if lowercased.contains("lifetime") { return TestData.lifetimePackage }
        if lowercased.contains("annual") || lowercased.contains("year") { return TestData.annualPackage }
        if lowercased.contains("six") || lowercased.contains("6_month") { return TestData.sixMonthPackage }
        if lowercased.contains("three") || lowercased.contains("3_month") { return TestData.threeMonthPackage }
        if lowercased.contains("week") { return TestData.weeklyPackage }
        return TestData.monthlyPackage
    }

    private static func describe(_ error: Error) -> String {
        func path(_ context: DecodingError.Context) -> String {
            context.codingPath.map(\.stringValue).joined(separator: ".")
        }

        switch error {
        case let DecodingError.dataCorrupted(context):
            return "dataCorrupted at \(path(context)): \(context.debugDescription)"
        case let DecodingError.keyNotFound(key, context):
            return "keyNotFound \(key.stringValue) at \(path(context))"
        case let DecodingError.typeMismatch(type, context):
            return "typeMismatch \(type) at \(path(context))"
        case let DecodingError.valueNotFound(type, context):
            return "valueNotFound \(type) at \(path(context))"
        default:
            return error.localizedDescription
        }
    }

}

// MARK: - View

@available(iOS 15.0, macOS 13.0, *)
struct LiveJSONPaywallView: View {

    @StateObject private var loader = LivePaywallJSONLoader()

    @State private var showHUD: Bool = false
    @State private var containerSize: CGSize = .zero
    @State private var showingFolderImporter: Bool = false

    var body: some View {
        // The paywall is the whole window, deliberately. `\.paywallWindowSize`
        // measures the paywall's container, so anything else drawn beside it would
        // make the responsive rules evaluate against a size the real app never
        // produces. Resize by resizing the window.
        self.paywallSurface
        .fileImporter(
            isPresented: self.$showingFolderImporter,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                self.loader.selectDirectory(url)
            }
        }
    }

    private var paywallSurface: some View {
        ZStack {
            if let offering = self.loader.offering {
                // No frame here: the paywall fills the window, so `paywallWindowSize`
                // tracks the window and the responsive rules evaluate against it.
                PaywallView(configuration: .init(
                    offering: offering,
                    displayCloseButton: false,
                    introEligibility: Self.introEligibility
                ))
                .id(self.loader.status.reloadCount)
            } else {
                self.placeholder
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { self.containerSize = proxy.size }
                    .onChangeOfSize(proxy.size) { self.containerSize = $0 }
            }
        )
        .overlay(alignment: .bottomTrailing) {
            self.hudToggle
        }
        .onAppear { Self.hideWindowTitle() }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape")
                .font(.largeTitle)
            Text("No paywall loaded")
                .font(.headline)
            if let message = self.loader.status.errorMessage {
                Text(message)
                    .font(.caption.monospaced())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            Button("Choose folder…") { self.showingFolderImporter = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var hudPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let label = Self.buildLabel {
                    Text(label)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Self.labelColor, in: Capsule())
                        .foregroundColor(.white)
                }
                Text("\(Int(self.containerSize.width)) × \(Int(self.containerSize.height))")
                    .font(.caption.monospacedDigit().bold())
                Text(self.aspectDescription)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
                Spacer(minLength: 12)
                Text("⟳ \(self.loader.status.reloadCount)")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Picker("File", selection: self.$loader.selectedFileName) {
                    ForEach(self.loader.availableFileNames, id: \.self) { name in
                        Text(name).tag(Optional(name))
                    }
                }
                .labelsHidden()
                .font(.caption2)

                Button("Folder…") { self.showingFolderImporter = true }
                    .font(.caption2)
                Button("Reload") { self.loader.reloadNow() }
                    .font(.caption2)
            }

            if let message = self.loader.status.errorMessage {
                Text(message)
                    .font(.caption2.monospaced())
                    .foregroundColor(.red)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .frame(minWidth: 280)
        .fixedSize(horizontal: false, vertical: true)
        .popoverSized()
    }

    /// The only chrome drawn over the paywall. Everything else lives in a popover,
    /// because anything painted on the surface sits inside `paywallWindowSize` and
    /// would read as part of the paywall in a screenshot.
    private var hudToggle: some View {
        Button {
            self.showHUD.toggle()
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
                .glassCircle()
        }
        .buttonStyle(.plain)
        .padding(22)
        .popover(isPresented: self.$showHUD, arrowEdge: .bottom) {
            self.hudPanel
        }
    }

    /// Which SDK variant this build is, so two identical-looking simulators are
    /// never confused for one another. Set at launch via LIVE_PAYWALL_LABEL.
    private static let buildLabel: String? = {
        let value = ProcessInfo.processInfo.environment["LIVE_PAYWALL_LABEL"] ?? ""
        return value.isEmpty ? nil : value
    }()

    private static var labelColor: Color {
        guard let label = Self.buildLabel?.lowercased() else { return .gray }
        if label.contains("fit") { return .purple }
        if label.contains("fill") { return .teal }
        return .gray
    }

    private var aspectDescription: String {
        guard self.containerSize.height > 0 else { return "" }
        return String(format: "%.2f", self.containerSize.width / self.containerSize.height)
    }

    /// Drops the app name from the Catalyst title bar. The bar itself stays, since
    /// that is what resizes the window, but the title is only ever noise in a
    /// screenshot of a paywall.
    private static func hideWindowTitle() {
        #if targetEnvironment(macCatalyst)
        for scene in UIApplication.shared.connectedScenes {
            (scene as? UIWindowScene)?.titlebar?.titleVisibility = .hidden
        }
        #endif
    }

    private static let introEligibility: TrialOrIntroEligibilityChecker = .init { packages in
        Dictionary(
            uniqueKeysWithValues: Set(packages).map { package in
                let status: IntroEligibilityStatus = package.storeProduct.hasIntroDiscount
                    ? .eligible
                    : .noIntroOfferExists
                return (package, status)
            }
        )
    }

}

// `onChange(of:)` moved to a two-parameter closure in iOS 17; this keeps one call site.
private extension View {

    @ViewBuilder
    func onChangeOfSize(_ size: CGSize, perform action: @escaping (CGSize) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.onChange(of: size) { _, newValue in action(newValue) }
        } else {
            self.onChange(of: size) { newValue in action(newValue) }
        }
    }

}


// MARK: - Chrome

private extension View {

    /// Liquid Glass where the OS has it, the old material everywhere else.
    @ViewBuilder
    func glassCircle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Circle())
        } else {
            self.background(.regularMaterial, in: Circle())
        }
    }

    /// Keeps the popover a popover on compact widths instead of letting it
    /// become a sheet, which would cover the paywall it is describing.
    @ViewBuilder
    func popoverSized() -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            self.presentationCompactAdaptation(.popover)
        } else {
            self
        }
    }
}


#endif
