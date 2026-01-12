import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ETagManagerTests: TestCase {
    let baseDirectory = URL(string: "data:mock-dir").unsafelyUnwrapped

    private var mockCache: SynchronizedLargeItemCache.MockUnderlyingSynchronizedFileCache!
    private var eTagManager: ETagManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let basePath = "SynchronizedLargeItemCacheTests-\(UUID().uuidString)"
        self.mockCache = SynchronizedLargeItemCache.MockUnderlyingSynchronizedFileCache(cacheDirectory: baseDirectory)
        self.eTagManager = .init(largeItemCache: SynchronizedLargeItemCache(cache: mockCache, basePath: basePath))

        // Stub: any unstubbed URL returns failure
        self.mockCache.stubDefaultLoadFile(with: .failure(SampleError()))
    }

    override func tearDown() {
        self.mockCache = nil
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
        mockCache.stubLoadFile(at: Self.testURL2, with: .failure(SampleError()))

        let header1 = self.eTagManager.eTagHeader(for: request1, withSignatureVerification: false)
        expect(header1[ETagManager.eTagRequestHeader.rawValue]) == Self.testETag

        let header2 = self.eTagManager.eTagHeader(for: request2, withSignatureVerification: false)
        expect(header2[ETagManager.eTagRequestHeader.rawValue]) == ""
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
        // Stub for saving the updated validation time
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = try XCTUnwrap(
            self.eTagManager.httpResultFromCacheOrBackend(
                with: self.responseForTest(url: Self.testURL,
                                           body: nil,
                                           eTag: Self.testETag,
                                           statusCode: .notModified),
                request: request,
                retried: false,
                isFallbackURLRequest: false
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
        // Stub successful save for the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: false,
            isFallbackURLRequest: false
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
        // Stub for the new response being saved
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let requestDate = Date().addingTimeInterval(-100000)

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: responseObject,
                                       eTag: Self.testETag,
                                       statusCode: .success,
                                       requestDate: requestDate),
            request: request,
            retried: false,
            isFallbackURLRequest: false
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
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).to(beNil())
    }

    func testBackendResponseIsReturnedIf304AndCantFindCachedAndItHasAlreadyRetried() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub no cached data found
        mockCache.stubLoadFile(at: Self.testURL, with: .failure(SampleError()))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .notModified
            ),
            request: request,
            retried: true,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .notModified
        expect(response?.body) == responseObject
    }

    func testReturnNullIf304AndNoResponseCached() throws {
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
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).to(beNil())
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationWasNotRequested() throws {
        let request = URLRequest(url: Self.testURL)

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

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
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(self.mockCache.saveDataInvocations.count) == 1

        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        expect(setData).toNot(beNil())

        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.eTag) == Self.testETag
        expect(eTagResponse.data) == responseObject
    }

    func testResponseIsStoredIfResponseCodeIs200AndVerificationSucceeded() throws {
        let request = URLRequest(url: Self.testURL)

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])
        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(self.mockCache.saveDataInvocations.count) == 1

        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        expect(setData).toNot(beNil())

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
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .internalServerError
        expect(response?.body) == responseObject

        expect(self.mockCache.saveDataInvocations.count) == 0
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
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(self.mockCache.saveDataInvocations.count) == 0
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
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(self.mockCache.saveDataInvocations.count) == 0
    }

    func testClearCachesWorks() throws {
        let request = URLRequest(url: Self.testURL)

        _ = try self.mockStoredETagResponse(for: request, statusCode: .success)

        eTagManager.clearCaches()

        expect(self.mockCache.removeInvocations.count) == 1
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
        mockCache.stubLoadFile(at: Self.testURL, with: .success(try XCTUnwrap(wrapper.asData)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: actualResponse,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: true,
            isFallbackURLRequest: false
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .notModified
        expect(response?.body) == actualResponse
    }

    func testETagHeaderIsNotFoundIfItsMissingResponseVerificationAndVerificationEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData))

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsFoundIfItsMissingResponseVerificationAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData))

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagRequestHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndVerificationIsEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationFailedAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerifiedOnDeviceAndVerificationIsEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verifiedOnDevice,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerifiedOnDeviceAndVerificationIsDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verifiedOnDevice,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsIgnoredIfVerificationNotRequestedAndVerificationIsEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]).to(beEmpty())
    }

    func testETagHeaderIsReturnedIfVerificationSuccededWithVerificationDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderIsReturnedIfVerificationSuccededWithVerificationEnabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: true)
        expect(response[ETagManager.eTagResponseHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderIsReturnedIfVerificationWasNotRequestedWithVerificationDisabled() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .notRequested,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request,
                                                   withSignatureVerification: false)
        expect(response[ETagManager.eTagResponseHeader.rawValue]) == Self.testETag
    }

    func testETagHeaderContainsValidationTime() throws {
        let request = URLRequest(url: Self.testURL)
        let validationTime = Date(timeIntervalSince1970: 800000)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            validationTime: validationTime,
            verificationResult: .notRequested,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response) == [
            ETagManager.eTagRequestHeader.rawValue: Self.testETag,
            ETagManager.eTagValidationTimeRequestHeader.rawValue: validationTime.millisecondsSince1970.description
        ]
    }

    func testETagHeaderDoesNotContainValidationTimeIfNotPresent() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            validationTime: nil,
            verificationResult: .notRequested,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))

        let response = self.eTagManager.eTagHeader(for: request, withSignatureVerification: false)
        expect(response) == [
            ETagManager.eTagRequestHeader.rawValue: Self.testETag
        ]
    }

    func testResponseReturnsRequestDateFromServer() throws {
        let request = URLRequest(url: Self.testURL)
        let requestDate = Date().addingTimeInterval(-100000)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       requestDate: requestDate),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )
        expect(response?.requestDate) == requestDate
    }

    func testResponseReturnsIsLoadShedderResponseValueFromDiskAndNotFromServer() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)",
        "is_load_shedder_response": false
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        var headers = self.getHeaders(eTag: Self.testETag)
        headers[HTTPClient.ResponseHeader.isLoadShedder.rawValue] = "true"

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: VerifiedHTTPResponse(
                httpStatusCode: .notModified,
                responseHeaders: headers,
                body: nil,
                verificationResult: .notRequested,
                isLoadShedderResponse: true,
                isFallbackUrlResponse: false
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )

        // Regardless of the source of the .notModified response, this property should always respect the value from
        // disk as it contains the truth of whether the cached (original) response was served by the Load Shedder,
        // Fallback Url or the main server
        expect(response?.originalSource) != .loadShedder
    }

    func testResponseReturnsIsFallbackUrlResponseValueFromDiskAndNotFromServer() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)",
        "is_fallback_url_response": false
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        var headers = self.getHeaders(eTag: Self.testETag)
        headers[HTTPClient.ResponseHeader.isLoadShedder.rawValue] = "true"

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: VerifiedHTTPResponse(
                httpStatusCode: .notModified,
                responseHeaders: headers,
                body: nil,
                verificationResult: .notRequested,
                isLoadShedderResponse: true,
                isFallbackUrlResponse: false
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: true
        )

        // Regardless of the source of the .notModified response, this property should always respect the value from
        // disk as it contains the truth of whether the cached (original) response was served by the Load Shedder,
        // Fallback Url or the main server
        expect(response?.originalSource) != .loadShedder
    }

    func testCachedResponseWithNoVerificationResultIsNotIgnored() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )
        expect(response?.verificationResult) == .notRequested
        expect(response?.body) == actualResponse
    }

    func testCachedResponseWithNoValidationTimeIsNotIgnored() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )
        expect(response?.requestDate).to(beNil())
        expect(response?.body) == actualResponse
    }

    func testCachedResponseIsFoundIfVerificationResultIsMissingAndVerificationNotRequested() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)"
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .notRequested),
            request: request,
            retried: true,
            isFallbackURLRequest: false
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .notRequested
    }

    func testCachedResponseIsFoundIfVerificationSucceeded() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success("""
        {
        "e_tag": "\(Self.testETag)",
        "status_code": 200,
        "data": "\(actualResponse.asFetchToken)",
        "verification_result": \(VerificationResult.verified.rawValue)
        }
        """.asData))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .verified),
            request: request,
            retried: true,
            isFallbackURLRequest: false
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

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .failed,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .failed),
            request: request,
            retried: true,
            isFallbackURLRequest: false
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .failed
    }

    func testCachedResponseIsReturnedWithNewVerificationResult() throws {
        let request = URLRequest(url: Self.testURL)

        let actualResponse = "response".asData

        mockCache.stubLoadFile(at: Self.testURL, with: .success(ETagManager.Response(
            eTag: Self.testETag,
            statusCode: .success,
            data: actualResponse,
            verificationResult: .verified,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ).asData()!))
        // Stub for saving the updated response
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(url: Self.testURL,
                                       body: nil,
                                       eTag: Self.testETag,
                                       statusCode: .notModified,
                                       verificationResult: .notRequested),
            request: request,
            retried: true,
            isFallbackURLRequest: false
        )
        expect(response).toNot(beNil())
        expect(response?.httpStatusCode) == .success
        expect(response?.body) == actualResponse
        expect(response?.verificationResult) == .notRequested
    }

    func testIsLoadShedderResponseIsStoredWhenHeaderIsTrue() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        var headers = self.getHeaders(eTag: Self.testETag)
        headers[HTTPClient.ResponseHeader.isLoadShedder.rawValue] = "true"

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: VerifiedHTTPResponse(
                httpStatusCode: .success,
                responseHeaders: headers,
                body: responseObject,
                verificationResult: .notRequested,
                isLoadShedderResponse: true,
                isFallbackUrlResponse: false
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        expect(self.mockCache.saveDataInvocations.count) == 1

        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.isLoadShedderResponse) == true
        expect(eTagResponse.isFallbackUrlResponse) == false
    }

    func testIsLoadShedderResponseIsFalseWhenHeaderIsNotTrue() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        // Test with header set to "false"
        var headers = self.getHeaders(eTag: Self.testETag)
        headers[HTTPClient.ResponseHeader.isLoadShedder.rawValue] = "false"

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: VerifiedHTTPResponse(
                httpStatusCode: .success,
                responseHeaders: headers,
                body: responseObject,
                verificationResult: .notRequested,
                isLoadShedderResponse: false,
                isFallbackUrlResponse: false
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.isLoadShedderResponse) == false
    }

    func testIsLoadShedderResponseIsFalseWhenHeaderIsMissing() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let headers = self.getHeaders(eTag: Self.testETag)
        // No isLoadShedder header

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: VerifiedHTTPResponse(
                httpStatusCode: .success,
                responseHeaders: headers,
                body: responseObject,
                verificationResult: .notRequested,
                isLoadShedderResponse: false,
                isFallbackUrlResponse: true
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.isLoadShedderResponse) == false
    }

    func testIsFallbackUrlResponseIsStoredWhenRequestIsFallback() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: true
        )

        expect(response).toNot(beNil())
        expect(self.mockCache.saveDataInvocations.count) == 1

        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.isFallbackUrlResponse) == true
        expect(eTagResponse.isLoadShedderResponse) == false
    }

    func testIsFallbackUrlResponseIsFalseWhenRequestIsNotFallback() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: self.responseForTest(
                url: Self.testURL,
                body: responseObject,
                eTag: Self.testETag,
                statusCode: .success
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: false
        )

        expect(response).toNot(beNil())
        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.isFallbackUrlResponse) == false
    }

    func testBothBooleansAreStoredCorrectlyTogether() throws {
        let request = URLRequest(url: Self.testURL)
        let responseObject = try JSONSerialization.data(withJSONObject: ["a": "response"])

        // Stub successful save
        mockCache.stubSaveData(at: Self.testURL, with: .success(.init(data: Data(), url: baseDirectory)))

        var headers = self.getHeaders(eTag: Self.testETag)
        headers[HTTPClient.ResponseHeader.isLoadShedder.rawValue] = "true"

        let response = self.eTagManager.httpResultFromCacheOrBackend(
            with: VerifiedHTTPResponse(
                httpStatusCode: .success,
                responseHeaders: headers,
                body: responseObject,
                verificationResult: .notRequested,
                isLoadShedderResponse: true,
                isFallbackUrlResponse: false
            ),
            request: request,
            retried: false,
            isFallbackURLRequest: true
        )

        expect(response).toNot(beNil())
        let setData = try XCTUnwrap(self.mockCache.saveDataInvocations.first?.data)
        let eTagResponse = try ETagManager.Response.with(setData)
        expect(eTagResponse.isLoadShedderResponse) == true
        expect(eTagResponse.isFallbackUrlResponse) == true
    }

    // MARK: - Old directory deletion

    func testDeletesOldETagCacheDirectoryFromDocuments() throws {
        // Create old ETag cache directory in documents directory
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let bundleID = Bundle.main.bundleIdentifier ?? "com.revenuecat"
        let oldETagDirectory = documentsURL.appendingPathComponent("\(bundleID).revenuecat.etags")
        let testFile = oldETagDirectory.appendingPathComponent("test-etag-file")

        // Create directory structure
        try FileManager.default.createDirectory(
            at: oldETagDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create a test file in the old directory
        try "test etag data".write(to: testFile, atomically: true, encoding: .utf8)

        // Verify old directory and file exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: oldETagDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        // Initialize ETagManager using default initializer (should delete old directory)
        let eTagManager = ETagManager()
        XCTAssertNotNil(eTagManager)

        // Verify old directory is deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldETagDirectory.path))

        // Verify new directory is created in cache location
        let newETagDirectory = try XCTUnwrap(DirectoryHelper.baseUrl(for: .cache)?.appendingPathComponent("etags"))

        XCTAssertTrue(FileManager.default.fileExists(atPath: newETagDirectory.path))
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
            verificationResult: verificationResult,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        )

        mockCache
            .stubLoadFile(at: request.url.unsafelyUnwrapped, with: .success(try XCTUnwrap(etagAndResponse.asData())))

        return data
    }

    func getCachedResponse(for request: URLRequest) throws -> ETagManager.Response {
        let savedData = try XCTUnwrap(self.mockCache.saveDataInvocations.filter({ data in
            data.url == request.url || data.url.absoluteString
                .contains(request.url?.absoluteString.asData.md5String ?? "this should not happen")
        }).first?.data)
        return try ETagManager.Response.with(savedData)
    }

    func responseForTest(
        url: URL,
        body: Data?,
        eTag: String?,
        statusCode: HTTPStatusCode,
        requestDate: Date? = nil,
        verificationResult: RevenueCat.VerificationResult = .defaultValue,
        isLoadShedderResponse: Bool = false,
        isFallbackUrlResponse: Bool = false
    ) -> VerifiedHTTPResponse<Data?> {
        return .init(httpStatusCode: statusCode,
                     responseHeaders: self.getHeaders(eTag: eTag),
                     body: body,
                     requestDate: requestDate,
                     verificationResult: verificationResult,
                     isLoadShedderResponse: isLoadShedderResponse,
                     isFallbackUrlResponse: isFallbackUrlResponse)
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

private struct SampleError: Error { }
