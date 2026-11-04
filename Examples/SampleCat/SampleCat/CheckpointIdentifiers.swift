import Foundation

/*
 The checkpoint identifiers that the Checkpoints tab fires. Create each checkpoint in the RevenueCat dashboard,
 or change these values to checkpoints that you already have.
 */
enum CheckpointIdentifiers {
    static let hardPaywall = "hard_paywall"
    static let softPaywall = "soft_paywall"
    static let onboardingComplete = "onboarding_complete"
    static let entitlementGate = "entitlement_gate"
}
