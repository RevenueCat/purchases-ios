# PR #6285 Review

## Must fix (blocking)

1. `PaywallComponent.Condition` API break  
   - `Sources/Paywalls/Components/Common/ComponentOverrides.swift:100` changes `Condition` from raw-value enum to associated-value enum.
   - Current public API is `public enum Condition: String` with `rawValue` / `init(rawValue:)` (`api/revenuecat-api-ios.swiftinterface:3840`).
   - Do not merge as-is. Keep public API stable (no `RawRepresentable` removal, no source-breaking enum shape changes).

2. Feature not wired into runtime override evaluation  
   - New condition types are only evaluated in the new overload, but call sites still use the legacy overload, e.g. `RevenueCatUI/Templates/V2/Components/Stack/StackComponentViewModel.swift:67`.
   - Legacy path hard-fails new conditions (`RevenueCatUI/Templates/V2/ViewModelHelpers/PresentedPartials.swift:162`).
   - Either:
     - wire `ConditionContext` through all `buildPartial` call paths, or
     - defer these new condition types until wiring exists.

3. Ambiguous fallback for partially-specified intro/promo conditions  
   - Decoder currently falls back to legacy `.introOffer` / `.promoOffer` when only one of `operator` / `value` is present (`Sources/Paywalls/Components/Common/ComponentOverrides.swift:184`).
   - Treat partial extended payloads as `.unsupported` to avoid silent behavior changes.

## Would add

1. Compatibility tests proving no public API regression (`api/*.swiftinterface` + API tester expectations).
2. Runtime evaluation tests (not only deserialization) for `variableCondition` and `selectedPackageCondition`.
3. Malformed extended intro/promo tests:
   - missing only `operator`
   - missing only `value`
   - wrong value types

## Would remove / change design-wise

1. Avoid public-surface expansion via associated-value enum cases. Use an internal decoded condition model and map into public-safe representation.
2. If public exposure is required, prefer a non-frozen-friendly pattern (struct + constants / payload structs), not adding/changing public enum cases.
