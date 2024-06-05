import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ETagManagerTests: TestCase {

    private var mockUserDefaults: MockUserDefaults! = nil
    private var eTagManager: ETagManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockUserDefaults = MockUserDefaults()
        self.eTagManager = .init(userDefaults: self.mockUserDefaults)
    }

    override func tearDown() {
        self.mockUserDefaults = nil
        self.eTagManager = nil

        super.tearDown()
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequest() {
        let request = URLRequest(url: Self.testURL)
        let header = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)

        let eTag = header[ETagManager.eTagRequestHeader.rawValue]
        expect(eTag) == ""
    }

    func testETagIsEmptyIfThereIsNoETagSavedForThatRequestWithDifferentURL() throws {
        let request1 = URLRequest(url: Self.testURL)
        let request2 = URLRequest(url: Self.testURL2)

        try self.mockStoredETagResponse(for: request1)

        let header = self.eTagManager.eTagHeader(for: request2, withSignatureVerification: false)
        expect(header[ETagManager.eTagRequestHeader.rawValue]) == ""
    }

    func testETagIsAddedToHeadersIfThereIsACachedETagForThatURL() throws {
        let request = URLRequest(url: Self.testURL)

        try self.mockStoredETagResponse(for: request)
        let header = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)

        expect(header[ETagManager.eTagRequestHeader.rawValue]) == Self.testETag
    }

    func testStoredResponseIsUsedIfResponseCodeIs304() throws {
        let request = URLRequest(url: Self.testURL)

        let cachedResponse = try self.mockStoredETagResponse(for: request, statusCode: .success)

        let response = try XCTUnwrap(
            self.eTagManager.httpResultFromCacheOrBackend(
                with: self.responseForTest(url: Self.testURL,
                                           body: nil,
                                           eTag: Self.testETag,
                                           statusCode: .notModified),
                request: request,
                retried: false
            )
        )

        expect(response.httpStatusCode) == .success
        expect(response.body) == cachedResponse
        expect(response.responseHeaders).toNot(beEmpty())
        expect(Set(response.responseHeaders.keys.compactMap { $0 as? String }))
        == Set(self.getHeaders(eTag: Self.testETag).keys)
    }

    func testValidationTimeIsUpdatedWhenUsingStoredResponse() throws {
        let request = URLRequest(url: Self.testURL)
        let validationTime = Date(timeIntervalSince1970: 10000)

        let cachedResponse = try self.mockStoredETagResponse(for: request,
                                                             statusCode: .success,
                                                             validationTime: validationTime)
        expect(try self.getCachedResponse(for: request).validationTime)
            .to(beCloseTo(validationTime, within: 1))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == cachedResponse

        let newCachedResponse = try self.getCachedResponse(for: request)
        expect(newCachedResponse.validationTime).toNot(beCloseTo(validationTime, within: 1))
        expect(newCachedResponse.validationTime).to(beCloseToNow())
    }

    func testStoredResponseIsNotUsedIfResponseCodeIs200() throws {
        let request = URLRequest(url: Self.testURL)

        _ = try self.mockStoredETagResponse(for: request, statusCode: .success)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let requestDate = Date().addingTimeInterval(-100000)

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: responseObject,
                                       eTag: Self.testETag,
                                       statusCode: .success,
                                       requestDate: requestDate),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == responseObject
        expect(response?.requestDate) == requestDate
    }

    func testResultIsNilIfResponseCodeIs304ButContainsNoETag() throws {
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: nil,
                                       statusCode: .notModified,
                                       requestDate: Date()),
            request: URLRequest(url: Self.testURL),
            retried: false
        )

        expect(response).to(beNil())
    }

    func testBackendResponseIsReturnedIf304AndCantFindCachedAndItHasAlreadyRetried() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .notModified
            ),
            request: request,
            retried: true
        )

        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .notModified
        expect(response?.body) == responseObject
    }

    func testReturnNullIf304AndCantFindCachedResponse() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .notModified
            ),
            request: request,
            retried: false
        )

        expect(response).to(beNil())
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationWasNotRequested() throws {
        let request = URLRequest(url: Self.testURL)
        let cacheKey = try request.cacheKey

        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success,
                verificationResult: .notRequested
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 1

        expect(self.mockUserDefaults.mockValues[try request.cacheKey]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[cacheKey] as? Data)

        expect(setData).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == cacheKey

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == Self.testETag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationSucceeded() throws {
        let request = URLRequest(url: Self.testURL)
        let cacheKey = try request.cacheKey

        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 1

        expect(self.mockUserDefaults.mockValues[try request.cacheKey]).toNot(beNil())
        let setData = try XCTUnwrap(self.mockUserDefaults.mockValues[try request.cacheKey] as? Data)

        expect(setData).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCalledValue) == cacheKey

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == Self.testETag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsNotStoredIfResponseCodeIs500() throws {
        let request = URLRequest(url: Self.testURL)

        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .internalServerError
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .internalServerError
        expect(response?.body) == responseObject

        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0

        expect(self.mockUserDefaults.mockValues[try request.cacheKey]).to(beNil())
    }

    func testResponseIsNotStoredIfVerificationFailed() throws {
        let request = URLRequest(url: Self.testURL)

        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success,
                verificationResult: .failed
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0
        expect(self.mockUserDefaults.mockValues[Self.testURL.absoluteString]).to(beNil())
    }

    func testResponseIsNotStoredIfVerifiedOnDevice() throws {
        let request = URLRequest(url: Self.testURL)

        let responseObject = Data()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success,
                verificationResult: .verifiedOnDevice
            ),
            request: request,
            retried: false
        )

        expect(response).toNot(beNil())
        expect(self.mockUserDefaults.setObjectForKeyCallCount) == 0
        expect(self.mockUserDefaults.mockValues[Self.testURL.absoluteString]).to(beNil())
    }

    func testClearCachesWorks() throws {
        let request = URLRequest(url: Self.testURL)

        _ = try self.mockStoredETagResponse(for: request, statusCode: .success)

        expect(self.mockUserDefaults.mockValues[try request.cacheKey]).toNot(beNil())

        eTagManager.clearCaches()

        expect(self.mockUserDefaults.mockValues.count) == 0
    }

    func testReadingETagWithInvalidBodyFormatFails() throws {
        /// The data that `ETagManager` serialized up until version 4.1.
        struct OldWrapper: Encodable {

            let eTag: String
            let statusCode: Int
            let responseObject: [String: AnyEncodable]

            var asData: Data? {
                return try? JSONSerialization.data(withJSONObject: self.asDictionary(),
                                                   options: .prettyPrinted)
            }

        }

        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        let wrapper = OldWrapper(eTag: Self.testETag,
                                 statusCode: HTTPStatusCode.success.rawValue,
                                 responseObject: [
                                    "response": AnyEncodable("cached")
                                 ])
        self.mockUserDefaults.mockValues[try request.cacheKey] = wrapper.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: actualResponse,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .notModified
        expect(response?.body) == actualResponse
    }

    func testETagHeaderIsNotFoundIfItsMissingResponseVerificationAndVerificationEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsFoundIfItsMissingResponseVerificationAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagRequestHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndVerificationIsEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerifiedOnDeviceAndVerificationIsEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verifiedOnDevice
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerifiedOnDeviceAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verifiedOnDevice
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationNotRequestedAndVerificationIsEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsReturnedIfVerificationSuccededWithVerificationDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderIsReturnedIfVerificationSuccededWithVerificationEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderIsReturnedIfVerificationWasNotRequestedWithVerificationDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderContainsValidationTime() throws {
        let request = URLRequest(url: Self.testURL)
        let validationTime = Date(timeIntervalSince1970: 800000)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            validationTime: validationTime,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response) == [
            ETagManager.eTagRequestHeader.rawValue: Self.testETag,
            ETagManager.eTagValidationTimeRequestHeader.rawValue: validationTime.millisecondsSince1970.description
        ]
    }

    func testETagHeaderDoesNotContainValidationTimeIfNotPresent() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            validationTime: nil,
            verificationResult: .notRequested
        ).asData()

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response) == [
            ETagManager.eTagRequestHeader.rawValue: Self.testETag
        ]
    }

    func testResponseReturnsRequestDateFromServer() throws {
        let request = URLRequest(url: Self.testURL)
        let requestDate = Date().addingTimeInterval(-100000)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       requestDate: requestDate),
            request: request,
            retried: false
        )
        expect(response?.requestDate) == requestDate
    }

    func testCachedResponseWithNoVerificationResultIsNotIgnored() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response?.verificationResult) == .notRequested
        expect(response?.body) == actualResponse
    }

    func testCachedResponseWithNoValidationTimeIsNotIgnored() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: false
        )
        expect(response?.requestDate).to(beNil())
        expect(response?.body) == actualResponse
    }

    func testCachedResponseIsFoundIfVerificationResultIsMissingAndVerificationNotRequested() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .notRequested),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .notRequested
    }

    func testCachedResponseIsFoundIfVerificationSucceeded() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = """
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)",
        "verification_result": \(VerificationResult.verified.rawValue)
        }
        """.asData

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .verified),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .verified
    }

    func testCachedResponseIsReturnedEvenIfVerificationFailed() throws {
        // Technically, as tested by `testResponseIsNotStoredIfVerificationFailed`
        // a response can't be stored if verification failed, but useful to test just in case.
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed
        ).asData()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .failed),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .failed
    }

    func testCachedResponseIsReturnedWithNewVerificationResult() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        self.mockUserDefaults.mockValues[try request.cacheKey] = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified
        ).asData()

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .notRequested),
            request: request,
            retried: true
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .notRequested
    }

}

private extension ETagManagerTests {

    func getHeaders(eTag: String?) -> [String: String] {
        return [
            "Content-Type": "application/json",
            "X-Platform": "android",
            "X-Platform-Flavor": "native",
            "X-Platform-Version": "29",
            "X-Version": "4.1.0",
            "X-Client-Locale": "en-US",
            "X-Client-Version": "1.0",
            "X-Observer-Mode-Enabled": "false",
            ETagManager.eTagRequestHeader.rawValue: eTag
        ]
            .compactMapValues { $0 }
            .merging(HTTPClient.authorizationHeader(withAPIKey: "apikey"))
    }

    @discardableResult
    func mockStoredETagResponse(for request: URLRequest,
                                statusCode: HTTPStatusCode = .success,
                                validationTime: Date? = nil,
                                verificationResult: RevenueCat.VerificationResult = .defaultValue) throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: ["arg": "value"])

        let etagAndResponse = ETagManager.Response(
            eTag: Self.testETag,
            statusCode: statusCode,
            data: data,
            validationTime: validationTime,
            verificationResult: verificationResult
        )
        self.mockUserDefaults.mockValues[try request.cacheKey] = try XCTUnwrap(etagAndResponse.asData())

        return data
    }

    func getCachedResponse(for request: URLRequest) throws -> ETagManager.Response {
        let cachedData = try XCTUnwrap(self.mockUserDefaults.mockValues[request.cacheKey] as? Data)
        return try ETagManager.Response.with(cachedData)
    }

    func responseForTest(
        url: URL,
        body: Data?,
        eTag: String?,
        statusCode: HTTPStatusCode,
        requestDate: Date? = nil,
        verificationResult: RevenueCat.VerificationResult = .defaultValue
    ) -> VerifiedHTTPResponse<Data?> {
        return .init(httpStatusCode: statusCode,
                     responseHeaders: self.getHeaders(eTag: eTag),
                     body: body,
                     requestDate: requestDate,
                     verificationResult: verificationResult)
    }

    private static let testURL = HTTPRequest.Path.getCustomerInfo(appUserID: "appUserID").url!
    private static let testURL2 = HTTPRequest.Path.getCustomerInfo(appUserID: "appUserID_2").url!

    static let testETag = "etag_1"

}

private extension ETagManager.Response {

    static func with(_ data: Data) throws -> Self {
        return try JSONDecoder.default.decode(jsonData: data)
    }

}

private extension URLRequest {

    var cacheKey: String {
        get throws {
            return try XCTUnwrap(ETagManager.cacheKey(for: self))
        }
    }

}
