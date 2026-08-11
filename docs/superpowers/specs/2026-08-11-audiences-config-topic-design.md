# Audiences Config Topic Design

## Goal

Allow typed SDK code to recognize and read the app-level `audiences` remote-config topic while deferring audience payload decoding until the rule-evaluation consumer is designed.

## Scope

- Add `audiences` to `RemoteConfigTopic` with the literal wire name `"audiences"`.
- Verify an `audiences` topic received through `/v1/config` is persisted and readable through `RemoteConfigManager`.
- Verify its prefetch-marked blob is handled by the existing generic remote-config prefetch path as opaque data.

The change will not introduce an audience model, an audiences config provider, an in-memory decoded-rules cache, or rule evaluation.

## Architecture and Data Flow

Remote-config synchronization remains string-keyed and already persists every active topic, including topics not represented by `RemoteConfigTopic`. It also proactively downloads blob references from items marked `prefetch`, independently of payload type.

Adding `RemoteConfigTopic.audiences` exposes the existing persisted topic through the manager's typed read facade. Audience payload bytes remain opaque in the shared blob store. A future rule-evaluation change can introduce the consumer-facing provider, choose the appropriate decoded representation, and add generation-guarded in-memory caching without replacing any temporary API from this change.

## Failure Handling

Missing or malformed audience payload content cannot invalidate the topic index or sibling blobs because this change does not decode payload bodies. Existing remote-config behavior continues to isolate blob download, checksum, and availability failures by blob reference.

## Testing

- Pin `RemoteConfigTopic.audiences.wireName` to `"audiences"` so fixtures derived from the enum cannot hide a wire-name mismatch.
- Add a focused integration test using the real `RemoteConfigManager` to show that an audiences topic is readable and its prefetch-marked opaque blob becomes available through `blobData`.
- Run the focused remote-config test suite, SwiftLint, and `swift build`.

## Deferred Work

The future rule-evaluation PR will define audience payload decoding, likely beginning from `rules: [String: AnyDecodable]`, and will own in-memory caching and malformed-payload semantics at that decoded boundary. This intentionally supersedes WFL-450's original acceptance criterion requiring decoded audience rules to be retained in memory.
