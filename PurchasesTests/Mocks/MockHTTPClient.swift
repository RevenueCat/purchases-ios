import Purchases
@testable import PurchasesCoreSwift

class MockHTTPClient: HTTPClient {

    var invokedPerformRequest = false
    var invokedPerformRequestCount = 0
    var shouldInvokeCompletion = true

    var stubbedCompletionStatusCode = 200
    var stubbedCompletionResponse: [AnyHashable: Any]? = [:]
    var stubbedCompletionError: Error? = nil

    var invokedPerformRequestParameters: (HTTPMethod: String,
                                          performSerially: Bool,
                                          path: String,
                                          requestBody: [AnyHashable: Any]?,
                                          headers: [String: String]?,
                                          completionHandler: HTTPClientResponseHandler?)?
    var invokedPerformRequestParametersList = [
        (HTTPMethod: String,
            performSerially: Bool,
            path: String,
            requestBody: [AnyHashable: Any]?,
            headers: [String: String]?,
            completionHandler: HTTPClientResponseHandler?)]()

    override func performRequest(_ httpMethod: String,
                                 performSerially: Bool = false,
                                 path: String,
                                 requestBody: [String : Any]?,
                                 headers: [String : String]?,
                                 completionHandler: HTTPClientResponseHandler?) {
        invokedPerformRequest = true
        invokedPerformRequestCount += 1
        invokedPerformRequestParameters = (httpMethod, performSerially, path, requestBody, headers, completionHandler)
        invokedPerformRequestParametersList.append((httpMethod, performSerially, path, requestBody, headers, completionHandler))
        if (shouldInvokeCompletion) {
            completionHandler?(stubbedCompletionStatusCode,
                               stubbedCompletionResponse,
                               stubbedCompletionError)
        }
    }
}
