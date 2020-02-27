import Purchases

class MockHTTPClient: RCHTTPClient {

//    override class func serverHostName() -> String { super.serverHostName() }

//    override func performRequest(_ HTTPMethod: String, path: String, body requestBody: [AnyHashable: Any]?,
//                                 headers: [String: String]?,
//                                 completionHandler: RCHTTPClientResponseHandler?) {
//        super.performRequest(HTTPMethod,
//                             path: path,
//                             body: requestBody,
//                             headers: headers,
//                             completionHandler: completionHandler)
//    }
//}

//class MockHTTPClient2: MockHTTPClient {

//    convenience init() {
//        self.init(platformFlavor: nil)
//    }

    var invokedPerformRequest = false
    var invokedPerformRequestCount = 0
    var invokedPerformRequestParameters: (HTTPMethod: String,
                                          path: String,
                                          requestBody: [AnyHashable: Any]?,
                                          headers: [String: String]?,
                                          completionHandler: RCHTTPClientResponseHandler?)?
    var invokedPerformRequestParametersList = [
        (HTTPMethod: String,
        path: String,
        requestBody: [AnyHashable: Any]?,
        headers: [String: String]?,
        completionHandler: RCHTTPClientResponseHandler?)]()

    override func performRequest(_ HTTPMethod: String, path: String, body requestBody: [AnyHashable: Any]?,
                                 headers: [String: String]?,
                                 completionHandler: RCHTTPClientResponseHandler?) {
        invokedPerformRequest = true
        invokedPerformRequestCount += 1
        invokedPerformRequestParameters = (HTTPMethod, path, requestBody, headers, completionHandler)
        invokedPerformRequestParametersList.append((HTTPMethod, path, requestBody, headers, completionHandler))
    }
}