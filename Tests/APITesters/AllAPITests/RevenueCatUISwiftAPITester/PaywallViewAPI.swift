//
//  PaywallViewAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 7/14/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

#if !os(tvOS) // For Paywalls V2
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct App: View {

    private var offering: Offering
    private var fonts: PaywallFontProvider
    private var purchaseOrRestoreCompleted: PurchaseOrRestoreCompletedHandler = { (_: CustomerInfo) in }
    @available(*, deprecated) // Ignore deprecation warnings
    private var purchaseStarted: PurchaseStartedHandler = { }
    private var purchaseOfPackageStarted: PurchaseOfPackageStartedHandler = { (_: Package) in }
    private var purchaseCompleted: PurchaseCompletedHandler = { (_: StoreTransaction?, _: CustomerInfo) in }
    private var purchaseCancelled: PurchaseCancelledHandler = { () in }
    private var restoreStarted: RestoreStartedHandler = { }
    private var failureHandler: PurchaseFailureHandler = { (_: NSError) in }

    private var purchaseInitiated = { (_: Package, _: ResumeAction) in }

    #if !os(watchOS)
    private var paywallTierChange: PaywallTierChangeHandler = { (_: PaywallData.Tier, _: String) in }
    #endif
    private var paywallDismissed: () -> Void = {}
    private var requestedDismissal: () -> Void = {}

    var body: some View {
        self.content
    }

    // Note: `body` is implicitly `MainActor`, but this is not on purpose
    // to ensure that these constructors can be called outside of `@MainActor`.
    @ViewBuilder
    var content: some View {
        PaywallView()
        PaywallView(displayCloseButton: true)
        PaywallView(fonts: self.fonts)
        PaywallView(fonts: self.fonts, displayCloseButton: true)
        PaywallView(offering: self.offering)
        PaywallView(offering: self.offering, displayCloseButton: true)
        PaywallView(offering: self.offering, fonts: self.fonts)
        PaywallView(offering: self.offering, fonts: self.fonts, displayCloseButton: true)
    }

    @ViewBuilder
    @available(*, deprecated) // Ignore deprecation warnings
    var checkDeprecatedPresentPaywallIfNeededWithRequiredEntitlement: some View {
        Text("")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    purchaseStarted: self.purchaseStarted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseStarted: self.purchaseStarted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseStarted: self.purchaseStarted,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    offering: self.offering,
                                    fonts: self.fonts,
                                    purchaseStarted: self.purchaseStarted,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    purchaseCancelled: self.purchaseCancelled,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    offering: self.offering,
                                    fonts: self.fonts,
                                    purchaseStarted: self.purchaseStarted,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    purchaseCancelled: self.purchaseCancelled,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    purchaseFailure: self.failureHandler,
                                    onDismiss: self.paywallDismissed)
    }

    @ViewBuilder
    var checkPresentPaywallIfNeededWithRequiredEntitlement: some View {
        Text("")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "")
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", offering: nil)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", offering: self.offering)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", fonts: self.fonts)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", presentationMode: .sheet)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "", presentationMode: .fullScreen)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    purchaseCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    purchaseCancelled: self.purchaseCancelled)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    restoreStarted: self.restoreStarted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    restoreCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    purchaseFailure: self.failureHandler)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    restoreFailure: self.failureHandler)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    offering: self.offering,
                                    fonts: self.fonts)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseStarted: nil)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseCancelled: self.purchaseCancelled)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    restoreStarted: self.restoreStarted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    restoreCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseFailure: self.failureHandler)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    restoreFailure: self.failureHandler)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted)
        }

    @ViewBuilder
    var checkPresentPaywallIfNeededWithRequiredEntitlement2: some View {
        Text("")

            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseStarted: nil,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    fonts: self.fonts,
                                    purchaseStarted: nil,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    offering: self.offering,
                                    fonts: self.fonts,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    offering: self.offering,
                                    fonts: self.fonts,
                                    purchaseStarted: self.purchaseOfPackageStarted,
                                    purchaseCompleted: self.purchaseOrRestoreCompleted,
                                    purchaseCancelled: self.purchaseCancelled,
                                    restoreStarted: self.restoreStarted,
                                    restoreCompleted: self.purchaseOrRestoreCompleted,
                                    purchaseFailure: self.failureHandler,
                                    onDismiss: self.paywallDismissed)
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: "",
                                    offering: self.offering,
                                    fonts: self.fonts,
                                    presentationMode: .fullScreen,
                                    purchaseStarted: nil,
                                    purchaseCompleted: nil,
                                    purchaseCancelled: nil,
                                    restoreStarted: nil,
                                    restoreCompleted: nil,
                                    purchaseFailure: nil,
                                    restoreFailure: nil,
                                    onDismiss: nil)
    }

    @ViewBuilder
    @available(*, deprecated) // Ignore deprecation warnings
    var checkDeprecatedPresentPaywallIfNeeded: some View {
        Text("")
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseStarted: {
                self.purchaseStarted()
            }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseStarted: {
                self.purchaseStarted()
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseStarted: {
                self.purchaseStarted()
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } onDismiss: {
                self.paywallDismissed()
            }
            .presentPaywallIfNeeded(offering: self.offering, fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseStarted: {
                self.purchaseStarted()
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } onDismiss: {
                self.paywallDismissed()
            }
            .presentPaywallIfNeeded(offering: self.offering, fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseStarted: {
                self.purchaseStarted()
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } purchaseCancelled: {
                self.purchaseCancelled()
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } purchaseFailure: {
                self.failureHandler($0)
            } restoreFailure: {
                self.failureHandler($0)
            } onDismiss: {
                self.paywallDismissed()
            }
    }

    @ViewBuilder
    var checkPresentPaywallIfNeeded: some View {
        Text("")
            .presentPaywallIfNeeded(offering: nil) { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded(offering: self.offering) { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded(offering: self.offering, fonts: self.fonts) { (_: CustomerInfo) in false }
            .presentPaywallIfNeeded(fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            }
            .presentPaywallIfNeeded(presentationMode: .sheet) { (_: CustomerInfo) in
                false
            }
            .presentPaywallIfNeeded(offering: self.offering, fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } purchaseCancelled: {
                self.purchaseCancelled()
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } onDismiss: {
                self.paywallDismissed()
            }
            .presentPaywallIfNeeded(offering: self.offering, fonts: self.fonts) { (_: CustomerInfo) in
                false
            } purchaseStarted: {
                self.purchaseOfPackageStarted($0)
            } purchaseCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } purchaseCancelled: {
                self.purchaseCancelled()
            } restoreStarted: {
                self.restoreStarted()
            } restoreCompleted: {
                self.purchaseOrRestoreCompleted($0)
            } purchaseFailure: {
                self.failureHandler($0)
            } restoreFailure: {
                self.failureHandler($0)
            } onDismiss: {
                self.paywallDismissed()
            }
            .presentPaywallIfNeeded(offering: nil,
                                    fonts: self.fonts,
                                    presentationMode: .fullScreen,
                                    shouldDisplay: { (_: CustomerInfo) in false },
                                    purchaseStarted: nil,
                                    purchaseCompleted: nil,
                                    purchaseCancelled: nil,
                                    restoreStarted: nil,
                                    restoreCompleted: nil,
                                    purchaseFailure: nil,
                                    restoreFailure: nil,
                                    onDismiss: nil)
    }

    @State private var offeringBinding: Offering?
    private var myAppPurchaseLogic: MyAppPurchaseLogic?

    @ViewBuilder
    var checkPresentPaywall: some View {
        let _: Binding<Offering?> = self.$offeringBinding

        Text("")
            .presentPaywall(offering: self.$offeringBinding)
            .presentPaywall(offering: self.$offeringBinding,
                            fonts: self.fonts)
            .presentPaywall(offering: self.$offeringBinding,
                            presentationMode: .sheet)
            .presentPaywall(offering: self.$offeringBinding,
                            presentationMode: .fullScreen)
            .presentPaywall(offering: self.$offeringBinding,
                            myAppPurchaseLogic: self.myAppPurchaseLogic)
            .presentPaywall(offering: self.$offeringBinding,
                            purchaseStarted: self.purchaseOfPackageStarted)
            .presentPaywall(offering: self.$offeringBinding,
                            purchaseCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywall(offering: self.$offeringBinding,
                            purchaseCancelled: self.purchaseCancelled)
            .presentPaywall(offering: self.$offeringBinding,
                            restoreStarted: self.restoreStarted)
            .presentPaywall(offering: self.$offeringBinding,
                            restoreCompleted: self.purchaseOrRestoreCompleted)
            .presentPaywall(offering: self.$offeringBinding,
                            purchaseFailure: self.failureHandler)
            .presentPaywall(offering: self.$offeringBinding,
                            restoreFailure: self.failureHandler)
            .presentPaywall(offering: self.$offeringBinding,
                            onDismiss: self.paywallDismissed)
            .presentPaywall(offering: self.$offeringBinding,
                            fonts: self.fonts,
                            presentationMode: .fullScreen,
                            myAppPurchaseLogic: self.myAppPurchaseLogic,
                            purchaseStarted: nil,
                            purchaseCompleted: nil,
                            purchaseCancelled: nil,
                            restoreStarted: nil,
                            restoreCompleted: nil,
                            purchaseFailure: nil,
                            restoreFailure: nil,
                            onDismiss: nil)
            .presentPaywall(offering: self.$offeringBinding,
                            fonts: self.fonts,
                            presentationMode: .sheet,
                            myAppPurchaseLogic: self.myAppPurchaseLogic,
                            purchaseStarted: self.purchaseOfPackageStarted,
                            purchaseCompleted: self.purchaseOrRestoreCompleted,
                            purchaseCancelled: self.purchaseCancelled,
                            restoreStarted: self.restoreStarted,
                            restoreCompleted: self.purchaseOrRestoreCompleted,
                            purchaseFailure: self.failureHandler,
                            restoreFailure: self.failureHandler,
                            onDismiss: self.paywallDismissed)
    }

    @available(*, deprecated) // Ignore deprecation warnings
    @ViewBuilder
    var checkDeprecatedPaywallFooter: some View {
        #if !os(watchOS)
        Text("")
            .paywallFooter(purchaseStarted: self.purchaseStarted)
            .paywallFooter(condensed: true,
                           purchaseStarted: self.purchaseStarted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering, purchaseStarted: self.purchaseStarted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           purchaseStarted: self.purchaseStarted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           purchaseStarted: self.purchaseStarted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter()
            .paywallFooter(purchaseStarted: self.purchaseOfPackageStarted)
            .paywallFooter(purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(purchaseCancelled: self.purchaseCancelled)
            .paywallFooter(restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(purchaseFailure: self.failureHandler)
            .paywallFooter(restoreFailure: self.failureHandler)
            .paywallFooter(fonts: self.fonts)
            .paywallFooter(fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true)
            .paywallFooter(condensed: true, fonts: self.fonts)
            .paywallFooter(condensed: true, purchaseStarted: nil)
            .paywallFooter(condensed: true, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           purchaseStarted: nil,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering)
            .paywallFooter(offering: offering, fonts: self.fonts)
            .paywallFooter(offering: offering, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering, fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreStarted: self.restoreStarted,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: nil,
                           purchaseCompleted: nil,
                           purchaseCancelled: nil,
                           restoreStarted: nil,
                           restoreCompleted: nil,
                           purchaseFailure: nil,
                           restoreFailure: nil)
            .paywallFooter(offering: offering)
            .paywallFooter(offering: offering,
                           condensed: true)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts)
            .paywallFooter(offering: offering,
                           condensed: true,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreStarted: self.restoreStarted,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           fonts: self.fonts)
            .paywallFooter(offering: offering,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           purchaseCancelled: self.purchaseCancelled)
            .paywallFooter(offering: offering,
                           restoreStarted: self.restoreStarted)
            .paywallFooter(offering: offering,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           purchaseFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreStarted: self.restoreStarted,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .paywallFooter(offering: offering,
                           fonts: self.fonts,
                           purchaseStarted: self.purchaseOfPackageStarted,
                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                           purchaseCancelled: self.purchaseCancelled,
                           restoreStarted: self.restoreStarted,
                           restoreCompleted: self.purchaseOrRestoreCompleted,
                           purchaseFailure: self.failureHandler,
                           restoreFailure: self.failureHandler)
            .paywallFooter(offering: offering,
                           condensed: true,
                           fonts: self.fonts,
                           purchaseStarted: nil,
                           purchaseCompleted: nil,
                           purchaseCancelled: nil,
                           restoreStarted: nil,
                           restoreCompleted: nil,
                           purchaseFailure: nil,
                           restoreFailure: nil)
            .onPaywallTierChange(self.paywallTierChange)
        #endif
    }

    @ViewBuilder
    var checkPaywallFooter: some View {
        #if !os(watchOS)

        Text("")
            .originalTemplatePaywallFooter()
            .originalTemplatePaywallFooter(purchaseStarted: self.purchaseOfPackageStarted)
            .originalTemplatePaywallFooter(purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(purchaseCancelled: self.purchaseCancelled)
            .originalTemplatePaywallFooter(restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(purchaseFailure: self.failureHandler)
            .originalTemplatePaywallFooter(restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(fonts: self.fonts)
            .originalTemplatePaywallFooter(fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(condensed: true)
            .originalTemplatePaywallFooter(condensed: true, fonts: self.fonts)
            .originalTemplatePaywallFooter(condensed: true, purchaseStarted: nil)
            .originalTemplatePaywallFooter(condensed: true, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(condensed: true,
                                           purchaseStarted: nil,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(condensed: true,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted)
            .originalTemplatePaywallFooter(condensed: true,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseCancelled: self.purchaseCancelled,
                                           restoreCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseFailure: self.failureHandler,
                                           restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(offering: offering)
            .originalTemplatePaywallFooter(offering: offering, fonts: self.fonts)
            .originalTemplatePaywallFooter(offering: offering, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering, restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering, fonts: self.fonts, purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseCancelled: self.purchaseCancelled,
                                           restoreStarted: self.restoreStarted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseFailure: self.failureHandler,
                                           restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: nil,
                                           purchaseCompleted: nil,
                                           purchaseCancelled: nil,
                                           restoreStarted: nil,
                                           restoreCompleted: nil,
                                           purchaseFailure: nil,
                                           restoreFailure: nil)
            .originalTemplatePaywallFooter(offering: offering)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           fonts: self.fonts)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseCancelled: self.purchaseCancelled,
                                           restoreStarted: self.restoreStarted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseFailure: self.failureHandler,
                                           restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts)
            .originalTemplatePaywallFooter(offering: offering,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           purchaseCancelled: self.purchaseCancelled)
            .originalTemplatePaywallFooter(offering: offering,
                                           restoreStarted: self.restoreStarted)
            .originalTemplatePaywallFooter(offering: offering,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           purchaseFailure: self.failureHandler)
            .originalTemplatePaywallFooter(offering: offering,
                                           restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseCancelled: self.purchaseCancelled,
                                           restoreStarted: self.restoreStarted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseFailure: self.failureHandler,
                                           restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           fonts: self.fonts,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted)
            .originalTemplatePaywallFooter(offering: offering,
                                           fonts: self.fonts,
                                           purchaseStarted: self.purchaseOfPackageStarted,
                                           purchaseCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseCancelled: self.purchaseCancelled,
                                           restoreStarted: self.restoreStarted,
                                           restoreCompleted: self.purchaseOrRestoreCompleted,
                                           purchaseFailure: self.failureHandler,
                                           restoreFailure: self.failureHandler)
            .originalTemplatePaywallFooter(offering: offering,
                                           condensed: true,
                                           fonts: self.fonts,
                                           purchaseStarted: nil,
                                           purchaseCompleted: nil,
                                           purchaseCancelled: nil,
                                           restoreStarted: nil,
                                           restoreCompleted: nil,
                                           purchaseFailure: nil,
                                           restoreFailure: nil)
        #endif
    }

    @ViewBuilder
    @available(*, deprecated) // Ignore deprecation warnings
    var checkDeprecatedPaywallViewModifiers: some View {
        Text("")
            .onPurchaseStarted(self.purchaseStarted)
    }

    @ViewBuilder
    var checkPaywallViewModifiers: some View {
        Text("")
            .onPurchaseInitiated(self.purchaseInitiated)
            .onPurchaseStarted(self.purchaseOfPackageStarted)
            .onPurchaseCompleted(self.purchaseOrRestoreCompleted)
            .onPurchaseCompleted(self.purchaseCompleted)
            .onPurchaseCancelled(self.purchaseCancelled)
            .onRestoreStarted(self.restoreStarted)
            .onRestoreCompleted(self.purchaseOrRestoreCompleted)
            .onRequestedDismissal(self.requestedDismissal)
    }

    @ViewBuilder
    var checkOnFailures: some View {
        Text("")
            .onPurchaseFailure(self.failureHandler)
            .onRestoreFailure(self.failureHandler)
    }

    private func fontProviders() {
        let _: PaywallFontProvider = DefaultPaywallFontProvider()
        let _: PaywallFontProvider = CustomPaywallFontProvider(fontName: "Papyrus")
    }

    private func presentationMode(_ mode: PaywallPresentationMode) {
        switch mode {
        case .sheet: break
        case .fullScreen: break
        }
    }

}

private struct CustomFontProvider: PaywallFontProvider {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func font(for textStyle: Font.TextStyle) -> Font {
        return Font.body
    }

}

#endif
