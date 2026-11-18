// Copyright RevenueCat Inc. All Rights Reserved.

#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
@_spi(Internal) @testable import RevenueCat
import Testing

@Suite("Audience compatibility", .serialized)
struct AudienceCompatibilityTests {

    @Test(arguments: try Self.loadBundle().cases)
    private func khepriConditionMatchesSDKResult(_ testCase: CompatibilityCase) async throws {
        let bundle = try Self.loadBundle()
        let profile = try #require(bundle.profiles[testCase.profile], "Profile for \(testCase.id)")
        let result = try await profile.evaluator().match(in: [testCase])
        #expect((result != nil) == testCase.expected, "Case \(testCase.id)")
    }

    @Test
    func requiredConditionsHaveExecutableCoverage() throws {
        let bundle = try Self.loadBundle()
        let requiredFields = Set(bundle.requiredFields)
        try #require(!requiredFields.isEmpty)
        let required = bundle.coverage.filter { requiredFields.contains($0.field) }
        #expect(Set(required.map(\.field)) == requiredFields)
        let incomplete = required.filter { $0.status != "covered" }
        #expect(
            incomplete.isEmpty,
            "\(incomplete.map { "\($0.field)/\($0.operator): \($0.status)" }.joined(separator: "\n"))"
        )
    }

    private static func loadBundle() throws -> CompatibilityBundle {
        let directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("AudienceCompatibility")
        let decoder = JSONDecoder.default
        let profiles = try decoder.decode(
            CompatibilityProfiles.self, from: Data(contentsOf: directory.appendingPathComponent("profiles.json"))
        )
        let coverage = try decoder.decode(
            CompatibilityCoverage.self, from: Data(contentsOf: directory.appendingPathComponent("coverage.json"))
        )
        try #require(profiles.schemaVersion == 1)
        try #require(coverage.schemaVersion == 1)
        try #require(!coverage.conditionFiles.isEmpty)
        var cases: [CompatibilityCase] = []
        for name in coverage.conditionFiles {
            let condition = try decoder.decode(
                CompatibilityCondition.self, from: Data(contentsOf: directory.appendingPathComponent(name))
            )
            try #require(condition.schemaVersion == 1, "\(name)")
            try #require(!condition.cases.isEmpty, "\(name)")
            cases.append(contentsOf: condition.cases)
        }
        return CompatibilityBundle(
            profiles: profiles.profiles, cases: cases,
            coverage: coverage.coverage, requiredFields: coverage.requiredFields
        )
    }

}

private struct CompatibilityBundle {

    let profiles: [String: CompatibilityProfile]
    let cases: [CompatibilityCase]
    let coverage: [CompatibilityCoverage.Row]
    let requiredFields: [String]

}

private struct CompatibilityProfiles: Decodable {

    let schemaVersion: Int
    let profiles: [String: CompatibilityProfile]

}

private struct CompatibilityCondition: Decodable {

    let schemaVersion: Int
    let cases: [CompatibilityCase]

}

private struct CompatibilityCoverage: Decodable {

    let schemaVersion: Int
    let conditionFiles: [String]
    let requiredFields: [String]
    let coverage: [Row]

    struct Row: Decodable {
        let field: String
        let `operator`: String
        let status: String
    }

}

private struct CompatibilityCase: Decodable, LocalRule {

    let id: String
    let profile: String
    let predicate: String
    let expected: Bool

}

extension CompatibilityCase: CustomTestStringConvertible {

    var testDescription: String { self.id }

}

private struct CompatibilityProfile: Decodable {

    let appUserId: String
    let evaluatedAt: TimeInterval
    let device: Device
    let storeCountry: String?
    let attributes: [String: Attribute]
    let customerInfo: [String: AnyDecodable]
    let subscriberDimensions: SubscriberDimensions

    struct Device: Decodable, Sendable {
        let appVersion: String
        let platform: String
        let platformVersion: [Int]
        let sdkVersion: String
        let locale: String?
    }

    struct Attribute: Decodable {
        let value: String
        let updatedAt: TimeInterval
    }

    func evaluator() throws -> LocalRulesEvaluator {
        let user = self.appUserId
        let device = self.device
        let storeCountry = self.storeCountry
        let customerInfo = try CustomerInfo(data: self.customerInfo.mapValues(\.asAny))
        let attributes = self.attributes.reduce(into: SubscriberAttribute.Dictionary()) { result, item in
            result[item.key] = SubscriberAttribute(
                withKey: item.key, value: item.value.value, isSynced: true,
                setTime: Date(timeIntervalSince1970: item.value.updatedAt)
            )
        }
        try #require(device.platformVersion.count == 3)
        let version = device.platformVersion
        return LocalRulesEvaluator(
            dimensionProviders: [
                DeviceDimensionProvider(
                    appVersion: device.appVersion, localeProvider: { device.locale }, platform: device.platform,
                    platformVersion: OperatingSystemVersion(
                        majorVersion: version[0], minorVersion: version[1], patchVersion: version[2]
                    ), sdkVersion: device.sdkVersion
                ),
                StoreDimensionProvider(storefrontCountryCodeProvider: { storeCountry }),
                CustomerInfoDimensionProvider(
                    currentAppUserIDProvider: { user }, customerInfoProvider: { _ in customerInfo }
                ),
                SubscriberAttributesDimensionProvider(attributesProvider: { attributes }),
                SubscriberDimensionsProvider(
                    store: SubscriberDimensionsStore(deviceCache: MockDeviceCache()),
                    currentUserProvider: MockCurrentUserProvider(mockAppUserID: user),
                    configProvider: CompatibilityDimensionsConfig(dimensions: self.subscriberDimensions)
                )
            ],
            currentAppUserIDProvider: { user },
            dateProvider: MockDateProvider(stubbedNow: Date(timeIntervalSince1970: self.evaluatedAt))
        )
    }

}

private final class CompatibilityDimensionsConfig: SubscriberDimensionsConfigProviderType {

    let value: SubscriberDimensions

    init(dimensions: SubscriberDimensions) {
        self.value = dimensions
    }

    func dimensions() async throws -> SubscriberDimensionsResolution { .resolved(self.value) }
    func cachedDimensions() -> SubscriberDimensionsResolution? { .resolved(self.value) }
    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {}

}

#endif
#endif
