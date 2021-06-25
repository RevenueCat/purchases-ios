import XCTest
import Nimble
import StoreKit

import Purchases
@testable import PurchasesCoreSwift

class ETagManagerTests: XCTestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var eTagManager: ETagManager!
    private var baseURL: URL = URL(string: "https://api.revenuecat.com")!
    
    override func setUp() {
        super.setUp()
        self.mockUserDefaults = MockUserDefaults()
        self.eTagManager = ETagManager(userDefaults: self.mockUserDefaults)
    }
    
    override func tearDown() {
        self.mockUserDefaults = nil
        self.eTagManager = nil
    }
    
    func testETagIsEmptyIfThereIsNoETagSavedForThatRequest() {
        let url = urlForTest()
        let request = URLRequest(url: url)
        let header = eTagManager.eTagHeader(for: request)
        let value2: String? = header[ETagManager.eTagHeaderName]

        expect(value2).toNot(beNil())
        expect(value2) == ""
    }

    func testETagIsAddedToHeadersIfThereIsACachedETagForThatURL() {
        let url = urlForTest()
        let _ = mockStoredETagAndResponse(for: url)
        let request = URLRequest(url: url)
        let header = eTagManager.eTagHeader(for: request)
        let value2: String? = header[ETagManager.eTagHeaderName]

        expect(value2).toNot(beNil())
        expect(value2) == "an_etag"
    }

    func testStoredResponseIsUsedIfResponseCodeIs304() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let cachedResponse = mockStoredETagAndResponse(for: url, statusCode: HTTPStatusCodes.success, eTag: eTag)
       
        guard let httpURLResponse = HTTPURLResponse(url: url, statusCode: HTTPStatusCodes.notModifiedResponseCode.rawValue, httpVersion: "HTTP/1.1", headerFields: getHeaders(eTag: eTag)) else {
            fatalError("Error initializing HTTPURLResponse")
        }
        let response = eTagManager.getHTTPResultFromCacheOrBackend(with: httpURLResponse, jsonObject: [:], error: nil, request: request, retried: false)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == HTTPStatusCodes.success.rawValue
        expect(response?.jsonObject as? [String: String]).to(equal(cachedResponse))
    }

    func testStoredResponseIsNotUsedIfResponseCodeIs200() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let _ = mockStoredETagAndResponse(for: url, statusCode: HTTPStatusCodes.success, eTag: eTag)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(url: url, eTag: eTag, statusCode: HTTPStatusCodes.success.rawValue)
        let response = eTagManager.getHTTPResultFromCacheOrBackend(
                with: httpURLResponse, jsonObject: responseObject, error: nil, request: request, retried: false)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == HTTPStatusCodes.success.rawValue
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))
    }

    func testBackendResponseIsReturnedIfThereIsAnError() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let _ = mockStoredETagAndResponse(for: url, statusCode: HTTPStatusCodes.success, eTag: eTag)
        let responseObject = ["a": "response"]
        let error = NSError(domain: NSCocoaErrorDomain, code: 123, userInfo: [:])
        let httpURLResponse = httpURLResponseForTest(
                url: url,
                eTag: eTag,
                statusCode: HTTPStatusCodes.notModifiedResponseCode.rawValue)
        let response = eTagManager.getHTTPResultFromCacheOrBackend(
                with: httpURLResponse, jsonObject: responseObject, error: error, request: request, retried: false)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == HTTPStatusCodes.notModifiedResponseCode.rawValue
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))
    }

    func testBackendResponseIsReturnedIf304AndCantFindCachedAndItHasAlreadyRetried() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(
                url: url,
                eTag: eTag,
                statusCode: HTTPStatusCodes.notModifiedResponseCode.rawValue)
        let response = eTagManager.getHTTPResultFromCacheOrBackend(
                with: httpURLResponse, jsonObject: responseObject, error: nil, request: request, retried: true)
        expect(response).toNot(beNil())
        expect(response?.statusCode) == HTTPStatusCodes.notModifiedResponseCode.rawValue
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))
    }

    func testReturnNullIf304AndCantFindCachedResponse() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(
                url: url,
                eTag: eTag,
                statusCode: HTTPStatusCodes.notModifiedResponseCode.rawValue)
        let response = eTagManager.getHTTPResultFromCacheOrBackend(
                with: httpURLResponse, jsonObject: responseObject, error: nil, request: request, retried: false)
        expect(response).to(beNil())
    }

    func testResponseIsStoredIfResponseCodeIs200() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]
        let httpURLResponse = httpURLResponseForTest(
                url: url,
                eTag: eTag,
                statusCode: HTTPStatusCodes.success.rawValue)
        let response = eTagManager.getHTTPResultFromCacheOrBackend(
                with: httpURLResponse, jsonObject: responseObject, error: nil, request: request, retried: false)

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 1

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())
        let setData: Data = self.mockUserDefaults.mockValues[cacheKey] as! Data

        expect(setData).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) ==  "https://api.revenuecat.com/v1/subscribers/appUserID"
        guard let eTagAndResponseWrapper = ETagAndResponseWrapper(with: setData) else {
            fatalError("Error creating ETagAndResponseWrapper")
        }
        expect(eTagAndResponseWrapper.eTag) == eTag
        expect(eTagAndResponseWrapper.jsonObject as? [String: String]) == responseObject
    }

    func testResponseIsNotStoredIfResponseCodeIst500() {
        let eTag = "an_etag"
        let url = urlForTest()
        let request = URLRequest(url: url)
        let responseObject = ["a": "response"]

        let httpURLResponse = httpURLResponseForTest(
                url: url,
                eTag: eTag,
                statusCode: HTTPStatusCodes.internalServerError.rawValue)
        let response = eTagManager.getHTTPResultFromCacheOrBackend(
                with: httpURLResponse, jsonObject: responseObject, error: nil, request: request, retried: false)

        expect(response).toNot(beNil())
        expect(response?.statusCode) == HTTPStatusCodes.internalServerError.rawValue
        expect(response?.jsonObject as? [String: String]).to(equal(responseObject))

        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).to(beNil())
    }

    func testClearCachesWorks() {
        let eTag = "an_etag"
        let url = urlForTest()
        let _ = mockStoredETagAndResponse(for: url, statusCode: HTTPStatusCodes.success, eTag: eTag)

        let cacheKey = url.absoluteString
        expect(self.mockUserDefaults.mockValues[cacheKey]).toNot(beNil())

        eTagManager.clearCaches()

        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    private func getHeaders(eTag: String) -> [String: String] {
        ["Content-Type": "application/json",
        "X-Platform": "android",
        "X-Platform-Flavor": "native",
        "X-Platform-Version": "29",
        "X-Version": "4.1.0",
        "X-Client-Locale": "en-US",
        "X-Client-Version": "1.0",
        "X-Observer-Mode-Enabled": "false",
        "Authorization": "Bearer apiKey",
        ETagManager.eTagHeaderName: eTag]
    }

    private func mockStoredETagAndResponse(for url: URL,
                                           statusCode: HTTPStatusCodes = HTTPStatusCodes.success,
                                           eTag: String = "an_etag") -> [String: String] {
        let jsonObject = ["arg": "value"]
        let etagAndResponse = ETagAndResponseWrapper(
                eTag: eTag,
                statusCode: statusCode.rawValue,
                jsonObject: jsonObject)
        let cacheKey = url.absoluteString
        self.mockUserDefaults.mockValues[cacheKey] = etagAndResponse.asData()
        return jsonObject
    }
    
    private func urlForTest() -> URL {
        guard let url: URL = URL(string: "/v1/subscribers/appUserID", relativeTo: baseURL) else {
            fatalError("Error initializing URL")
        }
        return url
    }

    private func httpURLResponseForTest(url: URL, eTag: String, statusCode: Int) -> HTTPURLResponse {
        guard let httpURLResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: getHeaders(eTag: eTag)
        ) else {
            fatalError("Error initializing HTTPURLResponse")
        }
        return httpURLResponse
    }

}
