//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPurchases.swift
//
//  Created by Nacho Soto on 10/10/22.

@testable import RevenueCat
import StoreKit

final class MockPurchases {

    @_disfavoredOverload
    fileprivate func unimplemented() {
        let _: Void = self.unimplemented()
    }

    fileprivate func unimplemented<T>() -> T {
        fatalError("Mocked method not implemented")
    }

    // MARK: -

    var invokedGetCustomerInfo = false
    var mockedCustomerInfoResponse: Result<CustomerInfo, PublicError> = .failure(
        ErrorUtils.unknownError().asPublicError
    )

    var invokedGetOfferings = false
    var invokedGetOfferingsParameters: OfferingsManager.FetchPolicy?
    var mockedOfferingsResponse: Result<Offerings, PublicError> = .failure(
        ErrorUtils.unknownError().asPublicError
    )

    var invokedHealthRequest = false
    var mockedHealthRequestResponse: Result<Void, PublicError> = .success(())
    var mockedHealthRequestWithSignatureVerificationResponse: Result<Void, PublicError> = .success(())

    var mockedProductEntitlementMapping: Result<ProductEntitlementMapping, PublicError> = .failure(
        ErrorUtils.unknownError().asPublicError
    )

    var mockedResponseVerificationMode: Signing.ResponseVerificationMode = .disabled

}

extension MockPurchases: InternalPurchasesType {

    func healthRequest(signatureVerification: Bool) async throws {
        if signatureVerification {
            return try self.mockedHealthRequestWithSignatureVerificationResponse.get()
        } else {
            return try self.mockedHealthRequestResponse.get()
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func productEntitlementMapping() async throws -> ProductEntitlementMapping {
        return try self.mockedProductEntitlementMapping.get()
    }

    var responseVerificationMode: Signing.ResponseVerificationMode {
        return self.mockedResponseVerificationMode
    }

}

extension MockPurchases: PurchasesType {

    func getCustomerInfo(completion: @escaping ((CustomerInfo?, PublicError?) -> Void)) {
        self.invokedGetCustomerInfo = true
        completion(self.mockedCustomerInfoResponse.value, self.mockedCustomerInfoResponse.error)
    }

    func getCustomerInfo(
        fetchPolicy: CacheFetchPolicy,
        completion: @escaping (CustomerInfo?, PublicError?) -> Void
    ) {
        self.getCustomerInfo(completion: completion)
    }

    func customerInfo() async throws -> CustomerInfo {
        self.invokedGetCustomerInfo = true
        return try self.mockedCustomerInfoResponse.get()
    }

    var cachedCustomerInfo: CustomerInfo? {
        return self.mockedCustomerInfoResponse.value
    }

    func getOfferings(completion: @escaping ((Offerings?, PublicError?) -> Void)) {
        self.invokedGetOfferings = true
        completion(self.mockedOfferingsResponse.value, self.mockedOfferingsResponse.error)
    }

    func offerings() async throws -> Offerings {
        return try await self.offerings(fetchPolicy: .default)
    }

    func offerings(fetchPolicy: OfferingsManager.FetchPolicy) async throws -> Offerings {
        self.invokedGetOfferings = true
        self.invokedGetOfferingsParameters = fetchPolicy
        return try self.mockedOfferingsResponse.get()
    }

    var cachedOfferings: Offerings? {
        return try? self.mockedOfferingsResponse.get()
    }

    // MARK: - Unimplemented

    var appUserID: String {
        self.unimplemented()
    }

    var isAnonymous: Bool {
        self.unimplemented()
    }

    var finishTransactions: Bool {
        get { self.unimplemented() }
        // swiftlint:disable:next unused_setter_value
        set { self.unimplemented() }
    }

    var purchasesAreCompletedBy: PurchasesAreCompletedBy {
        get { self.unimplemented() }
        // swiftlint:disable:next unused_setter_value
        set { self.unimplemented() }
    }

    var delegate: PurchasesDelegate? {
        get { self.unimplemented() }
        // swiftlint:disable:next unused_setter_value
        set { self.unimplemented() }
    }

    func logIn(
        _ appUserID: String,
        completion: @escaping (CustomerInfo?,
        Bool,
        PublicError?
    ) -> Void) {
        self.unimplemented()
    }

    func logIn(
        _ appUserID: String
    ) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        self.unimplemented()
    }

    func logOut(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.unimplemented()
    }

    func logOut() async throws -> CustomerInfo {
        self.unimplemented()
    }

    func syncAttributesAndOfferingsIfNeeded(
        completion: @escaping (RevenueCat.Offerings?, RevenueCat.PublicError?) -> Void
    ) {
        self.unimplemented()
    }

    func syncAttributesAndOfferingsIfNeeded() async throws -> Offerings? {
        self.unimplemented()
    }

    func customerInfo(fetchPolicy: CacheFetchPolicy) async throws -> CustomerInfo {
        self.unimplemented()
    }

    func getProducts(_ productIdentifiers: [String], completion: @escaping ([StoreProduct]) -> Void) {
        self.unimplemented()
    }

    func products(_ productIdentifiers: [String]) async -> [StoreProduct] {
        self.unimplemented()
    }

    func purchase(product: StoreProduct, completion: @escaping PurchaseCompletedBlock) {
        self.unimplemented()
    }

    func purchase(product: StoreProduct) async throws -> PurchaseResultData {
        self.unimplemented()
    }

    func purchase(package: Package, completion: @escaping PurchaseCompletedBlock) {
        self.unimplemented()
    }

    func purchase(package: Package) async throws -> PurchaseResultData {
        self.unimplemented()
    }

    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer,
        completion: @escaping PurchaseCompletedBlock
    ) {
        self.unimplemented()
    }

    func purchase(
        product: StoreProduct,
        promotionalOffer: PromotionalOffer
    ) async throws -> PurchaseResultData {
        self.unimplemented()
    }

    func purchase(
        package: Package,
        promotionalOffer: PromotionalOffer,
        completion: @escaping PurchaseCompletedBlock
    ) {
        self.unimplemented()
    }

    func purchase(
        package: Package,
        promotionalOffer: PromotionalOffer
    ) async throws -> PurchaseResultData {
        self.unimplemented()
    }

    #if ENABLE_PURCHASE_PARAMS
    func purchase(_ params: PurchaseParams, completion: @escaping PurchaseCompletedBlock) {
        self.unimplemented()
    }

    func purchase(_ params: PurchaseParams) async throws -> PurchaseResultData {
        self.unimplemented()
    }
    #endif

    func restorePurchases(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.unimplemented()
    }

    func restorePurchases() async throws -> CustomerInfo {
        self.unimplemented()
    }

    func syncPurchases(completion: ((CustomerInfo?, PublicError?) -> Void)?) {
        self.unimplemented()
    }

    func syncPurchases() async throws -> CustomerInfo {
        self.unimplemented()
    }

    func checkTrialOrIntroDiscountEligibility(
        productIdentifiers: [String],
        completion receiveEligibility: @escaping ([String: IntroEligibility]) -> Void
    ) {
        self.unimplemented()
    }

    func checkTrialOrIntroDiscountEligibility(
        productIdentifiers: [String]
    ) async -> [String: IntroEligibility] {
        self.unimplemented()
    }

    func checkTrialOrIntroDiscountEligibility(
        product: StoreProduct,
        completion: @escaping (IntroEligibilityStatus) -> Void
    ) {
        self.unimplemented()
    }

    func checkTrialOrIntroDiscountEligibility(
        product: StoreProduct
    ) async -> IntroEligibilityStatus {
        self.unimplemented()
    }

    func getPromotionalOffer(
        forProductDiscount discount: StoreProductDiscount,
        product: StoreProduct,
        completion: @escaping ((PromotionalOffer?, PublicError?) -> Void)
    ) {
        self.unimplemented()
    }

    func promotionalOffer(
        forProductDiscount discount: StoreProductDiscount,
        product: StoreProduct
    ) async throws -> PromotionalOffer {
        self.unimplemented()
    }

    func eligiblePromotionalOffers(forProduct product: StoreProduct) async -> [PromotionalOffer] {
        self.unimplemented()
    }

    func invalidateCustomerInfoCache() {
        self.unimplemented()
    }

    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        self.unimplemented()
    }

    func beginRefundRequest(forEntitlement entitlementID: String) async throws -> RefundRequestStatus {
        self.unimplemented()
    }

    func beginRefundRequestForActiveEntitlement() async throws -> RefundRequestStatus {
        self.unimplemented()
    }

    #if os(iOS) || VISION_OS

    func presentCodeRedemptionSheet() {
        self.unimplemented()
    }

    #endif

    func showPriceConsentIfNeeded() {
        self.unimplemented()
    }

    func showManageSubscriptions(completion: @escaping (PublicError?) -> Void) {
        self.unimplemented()
    }

    func showManageSubscriptions() async throws {
        self.unimplemented()
    }

    var attribution: Attribution {
        self.unimplemented()
    }

    func setAttributes(_ attributes: [String: String]) {
        self.unimplemented()
    }

    var allowSharingAppStoreAccount: Bool {
        get { self.unimplemented() }
        // swiftlint:disable:next unused_setter_value
        set { self.unimplemented() }
    }

    func setEmail(_ email: String?) {
        self.unimplemented()
    }

    func setPhoneNumber(_ phoneNumber: String?) {
        self.unimplemented()
    }

    func setDisplayName(_ displayName: String?) {
        self.unimplemented()
    }

    func setPushToken(_ pushToken: Data?) {
        self.unimplemented()
    }

    func setPushTokenString(_ pushToken: String?) {
        self.unimplemented()
    }

    func setAdjustID(_ adjustID: String?) {
        self.unimplemented()
    }

    func setAppsflyerID(_ appsflyerID: String?) {
        self.unimplemented()
    }

    func setFBAnonymousID(_ fbAnonymousID: String?) {
        self.unimplemented()
    }

    func setMparticleID(_ mparticleID: String?) {
        self.unimplemented()
    }

    func setOnesignalID(_ onesignalID: String?) {
        self.unimplemented()
    }

    func setMediaSource(_ mediaSource: String?) {
        self.unimplemented()
    }

    func setCampaign(_ campaign: String?) {
        self.unimplemented()
    }

    func setAdGroup(_ adGroup: String?) {
        self.unimplemented()
    }

    func setAd(_ value: String?) {
        self.unimplemented()
    }

    func setKeyword(_ keyword: String?) {
        self.unimplemented()
    }

    func setCreative(_ creative: String?) {
        self.unimplemented()
    }

    func setCleverTapID(_ cleverTapID: String?) {
        self.unimplemented()
    }

    func setMixpanelDistinctID(_ mixpanelDistinctID: String?) {
        self.unimplemented()
    }

    func setFirebaseAppInstanceID(_ firebaseAppInstanceID: String?) {
        self.unimplemented()
    }

    func setTenjinAnalyticsInstallationID(_ tenjinAnalyticsInstallationID: String?) {
        self.unimplemented()
    }

    func collectDeviceIdentifiers() {
        self.unimplemented()
    }

}

extension MockPurchases: PurchasesSwiftType {

    var customerInfoStream: AsyncStream<CustomerInfo> {
        self.unimplemented()
    }

    func beginRefundRequest(
        forProduct productID: String,
        completion: @escaping (Result<RefundRequestStatus, PublicError>) -> Void
    ) {
        self.unimplemented()
    }

    func beginRefundRequest(
        forEntitlement entitlementID: String,
        completion: @escaping (Result<RefundRequestStatus, PublicError>) -> Void
    ) {
        self.unimplemented()
    }

    func beginRefundRequestForActiveEntitlement(
        completion: @escaping (Result<RefundRequestStatus, PublicError>) -> Void
    ) {
        self.unimplemented()
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func recordPurchase(
        _ purchaseResult: Product.PurchaseResult
    ) async throws -> RevenueCat.StoreTransaction? {
        self.unimplemented()
    }

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

    @available(iOS 16.0, *)
    func showStoreMessages(for types: Set<StoreMessageType> = Set(StoreMessageType.allCases)) async {
        self.unimplemented()
    }

    #endif

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func eligibleWinBackOffers(
        forProduct product: StoreProduct
    ) async throws -> [WinBackOffer] {
        self.unimplemented()
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    func eligibleWinBackOffers(
        forProduct product: StoreProduct,
        completion: @escaping (Result<[WinBackOffer], PublicError>) -> Void
    ) {
        self.unimplemented()
    }
}
