import XCTest
import Nimble

@testable import Purchases

class PurchaserInfoManagerTests: XCTestCase {
    func testFetchAndCachePurchaserInfoDoesntAllowSimultaneousCalls() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoCallsBackendWithRandomDelayIfAppBackgrounded() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoCallsBackendWithoutRandomDelayIfAppForegrounded() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoPassesBackendErrors() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoClearsPurchaserInfoTimestampIfBackendError() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoCachesIfSuccessful() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoCallsCompletionOnMainThread() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoIfStaleFechesIfStale() {
        // TODO: implement
    }

    func testFetchAndCachePurchaserInfoIfStaleFechesIfCacheEmpty() {
        // TODO: implement
    }

    func testSendUpdatedPurchaserInfoToDelegateIfChangedSendsIfNeverSent() {
        // TODO: implement
    }

    func testSendUpdatedPurchaserInfoToDelegateIfChangedSendsIfDifferent() {
        // TODO: implement
    }

    func testSendUpdatedPurchaserInfoToDelegateIfChangedSendsOnMainThread() {
        // TODO: implement
    }

    func testPurchaserInfoReturnsFromCacheIfAvailable() {
        // TODO: implement
    }

    func testPurchaserInfoReturnsFromCacheAndRefreshesIfStale() {
        // TODO: implement
    }

    func testPurchaserInfoFetchesIfNoCache() {
        // TODO: implement
    }

    func testCachedPurchaserInfoParsesCorrectly() {
        // TODO: implement
    }

    func testCachedPurchaserInfoReturnsNilIfNotAvailable() {
        // TODO: implement
    }

    func testCachedPurchaserInfoReturnsNilIfCantBeParsed() {
        // TODO: implement
    }

    func testCachedPurchaserInfoReturnsNilIfDifferentSchema() {
        // TODO: implement
    }

    func testCachePurchaserInfoStoresCorrectly() {
        // TODO: implement
    }

    func testCachePurchaserDoesntStoreIfEmpty() {
        // TODO: implement
    }

    func testCachePurchaserDoesntStoreNoJsonObject() {
        // TODO: implement
    }

    func testCachePurchaserDoesntStoreIfCantBeSerialized() {
        // TODO: implement
    }

    func testCachePurchaserSendsToDelegateIfChanged() {
        // TODO: implement
    }

    func testClearPurchaserInfoCacheClearsCorrectly() {
        // TODO: implement
    }

    func testClearPurchaserInfoCacheResetsLastSent() {
        // TODO: implement
    }
}