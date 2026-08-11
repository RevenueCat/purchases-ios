# Audiences Config Topic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Register the app-level `audiences` remote-config topic and verify its opaque prefetched blobs use the existing persistence and prefetch pipeline.

**Architecture:** Extend the internal typed topic facade with one wire-name case. Keep audience payloads opaque and exercise the real `RemoteConfigManager`, disk cache, blob store, source provider, and blob fetcher in an integration test; decoding and an audience-specific provider remain deferred.

**Tech Stack:** Swift 5.9+, XCTest, Nimble, Swift Package Manager, SwiftLint.

## Global Constraints

- Do not add a public API or a new public enum.
- Do not add an audience payload model, audience-specific provider, decoded-rules cache, or rule evaluation.
- Preserve the generic string-keyed remote-config sync behavior for unknown server topics.
- Keep compatibility with iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, and visionOS 1.0.
- Keep the implementation diff minimal and run SwiftLint plus `swift build` before completion.

---

### Task 1: Register and verify the audiences topic

**Files:**
- Modify: `Sources/Networking/RemoteConfigTopic.swift`
- Modify: `Tests/UnitTests/Networking/RemoteConfig/RemoteConfigIntegrationTests.swift`

**Interfaces:**
- Consumes: `RemoteConfigManager.topic(_:)`, `RemoteConfigManager.blobData(for:itemKey:)`, and `RemoteConfigManager.awaitTopicAndPrefetchBlobsReady(_:)`.
- Produces: internal `RemoteConfigTopic.audiences` with `wireName == "audiences"`.

- [x] **Step 1: Write the failing registration and opaque-prefetch tests**

Add these tests to `RemoteConfigIntegrationTests`:

```swift
func testAudiencesTopicWireNameMatchesBackend() {
    expect(RemoteConfigTopic.audiences.wireName) == "audiences"
}

func testAudiencesTopicPrefetchesOpaquePayloadWithoutRequiringEveryItemBody() async throws {
    let opaquePayload = Data("not-json".utf8)
    let ref = RCContainerTestData.blobRef(for: opaquePayload)
    let source = Self.blobSource("primary")
    let audiences: RemoteConfiguration.ConfigTopic = [
        "aud_valid": .init(blobRef: ref, prefetch: true),
        "aud_missing": .init(prefetch: true)
    ]
    let container = try Self.containerData(topics: .init(entries: [
        RemoteConfigTopic.sources.wireName: Self.sourcesTopic(blobSources: [source]),
        RemoteConfigTopic.audiences.wireName: audiences
    ]))
    await self.downloader.setResponse(.success(opaquePayload), for: source, ref: ref)

    await self.refresh(with: container)
    let topic = await self.manager.awaitTopicAndPrefetchBlobsReady(.audiences)
    let prefetchedData = self.blobStore.read(ref: ref)
    let validData = await self.manager.blobData(for: .audiences, itemKey: "aud_valid")
    let missingData = await self.manager.blobData(for: .audiences, itemKey: "aud_missing")

    expect(topic?.keys.sorted()) == ["aud_missing", "aud_valid"]
    expect(topic?["aud_valid"]?.prefetch) == true
    expect(prefetchedData) == opaquePayload
    expect(validData) == opaquePayload
    expect(missingData).to(beNil())
}
```

The non-JSON bytes prove this PR does not decode audience bodies. The body-less sibling proves a missing item does not invalidate the topic or the valid prefetched item.

- [x] **Step 2: Run the focused tests and verify RED**

Run:

```bash
xcodebuild test -quiet \
  -workspace RevenueCat.xcworkspace \
  -scheme RevenueCat \
  -testPlan CI-RevenueCat \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  -only-testing:UnitTests/RemoteConfigIntegrationTests/testAudiencesTopicWireNameMatchesBackend \
  -only-testing:UnitTests/RemoteConfigIntegrationTests/testAudiencesTopicPrefetchesOpaquePayloadWithoutRequiringEveryItemBody \
  CODE_SIGNING_ALLOWED=NO
```

Expected: compilation fails because `RemoteConfigTopic` has no member `audiences`.

- [x] **Step 3: Add the minimal topic registration**

Add the case to `RemoteConfigTopic`:

```swift
case audiences
```

No explicit raw value is needed because the Swift case name exactly matches the backend wire name.

- [x] **Step 4: Run the focused tests and verify GREEN**

Run:

```bash
xcodebuild test -quiet \
  -workspace RevenueCat.xcworkspace \
  -scheme RevenueCat \
  -testPlan CI-RevenueCat \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  -only-testing:UnitTests/RemoteConfigIntegrationTests/testAudiencesTopicWireNameMatchesBackend \
  -only-testing:UnitTests/RemoteConfigIntegrationTests/testAudiencesTopicPrefetchesOpaquePayloadWithoutRequiringEveryItemBody \
  CODE_SIGNING_ALLOWED=NO
```

Expected: both audience-topic tests pass.

- [x] **Step 5: Run regression verification**

Run:

```bash
xcodebuild test -quiet \
  -workspace RevenueCat.xcworkspace \
  -scheme RevenueCat \
  -testPlan CI-RevenueCat \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' \
  -only-testing:UnitTests/RemoteConfigIntegrationTests \
  CODE_SIGNING_ALLOWED=NO
swiftlint
swift build
git diff --check
```

Expected: tests, lint, and build pass with no whitespace errors.

- [x] **Step 6: Commit the implementation**

```bash
git add Sources/Networking/RemoteConfigTopic.swift Tests/UnitTests/Networking/RemoteConfig/RemoteConfigIntegrationTests.swift docs/superpowers/plans/2026-08-11-audiences-config-topic.md
git commit -m "feat: ingest audiences config topic"
```
