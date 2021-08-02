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
                                          completionHandler: ((Int, [AnyHashable: Any]?, Error?) -> Void)?)?
    var invokedPerformRequestParametersList = [
        (HTTPMethod: String,
         performSerially: Bool,
         path: String,
         requestBody: [AnyHashable: Any]?,
         headers: [String: String]?,
         completionHandler: ((Int, [AnyHashable: Any]?, Error?) -> Void)?)]()
    
    override func performGETRequest(performSerially: Bool = false,
                                    path: String,
                                    headers: [String : String],
                                    completionHandler: ((Int, [AnyHashable : Any]?, Error?) -> Void)?) {
        performRequest("GET", performSerially: performSerially, path: path, requestBody: nil, headers: headers, completionHandler: completionHandler)
    }
    
    override func performPOSTRequest(performSerially: Bool = false,
                                     path: String,
                                     requestBody: [String: Any],
                                     headers: [String : String],
                                     completionHandler: ((Int, [AnyHashable : Any]?, Error?) -> Void)?) {
        performRequest("POST", performSerially: performSerially, path: path, requestBody: requestBody, headers: headers, completionHandler: completionHandler)
    }
}

private extension MockHTTPClient {
    func performRequest(_ httpMethod: String,
                        performSerially: Bool,
                        path: String,
                        requestBody: [String : Any]?,
                        headers: [String : String]?,
                        completionHandler: ((Int, [AnyHashable: Any]?, Error?) -> Void)?) {
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
