//
//  RCHTTPClient.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCHTTPClient.h"
#import "RCLogUtils.h"
#import "RCHTTPStatusCodes.h"
#import "RCSystemInfo.h"
#import "RCHTTPRequest.h"
#import "RCPurchasesErrorUtils.h"
@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN

@interface RCHTTPClient ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) RCSystemInfo *systemInfo;
@property (nonatomic) NSMutableArray<RCHTTPRequest *> *queuedRequests;
@property (nonatomic, nullable) RCHTTPRequest *currentSerialRequest;

@end


@implementation RCHTTPClient

- (instancetype)initWithSystemInfo:(RCSystemInfo *)systemInfo {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 1;
        self.session = [NSURLSession sessionWithConfiguration:config];
        self.systemInfo = systemInfo;
        self.queuedRequests = [[NSMutableArray alloc] init];
        self.currentSerialRequest = nil;
    }
    return self;
}

- (void)performRequest:(NSString *)httpMethod
                  path:(NSString *)path
                  body:(nullable NSDictionary *)requestBody
               headers:(nullable NSDictionary<NSString *, NSString *> *)headers
     completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler {
    [self performRequest:httpMethod
                serially:NO
                    path:path
                    body:requestBody
                 headers:headers
       completionHandler:completionHandler];
}

- (void)performRequest:(NSString *)httpMethod
              serially:(BOOL)performSerially
                  path:(NSString *)path
                  body:(nullable NSDictionary *)requestBody
               headers:(nullable NSDictionary<NSString *, NSString *> *)headers
     completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler {
    [self assertIsValidRequestWithMethod:httpMethod body:requestBody];

    NSMutableDictionary *defaultHeaders = self.defaultHeaders.mutableCopy;
    [defaultHeaders addEntriesFromDictionary:headers];

    NSMutableURLRequest * _Nullable urlRequest = [self createRequestWithMethod:httpMethod
                                                                          path:path
                                                                   requestBody:requestBody
                                                                       headers:defaultHeaders];
    if (!urlRequest) {
        RCErrorLog(@"Could not create request to %@ with body %@", path, requestBody);
        completionHandler(-1,
                          nil,
                          [RCPurchasesErrorUtils networkErrorWithUnderlyingError:RCPurchasesErrorUtils.unknownError]);
        return;
    }

    if (performSerially) {
        RCHTTPRequest *rcRequest = [[RCHTTPRequest alloc] initWithHTTPMethod:httpMethod
                                                                        path:path
                                                                        body:requestBody
                                                                     headers:headers
                                                           completionHandler:completionHandler];
        @synchronized (self) {
            if (self.currentSerialRequest) {
                RCDebugLog(RCStrings.network.serial_request_queued,
                           (unsigned long)self.queuedRequests.count,
                           httpMethod,
                           path);
                [self.queuedRequests addObject:rcRequest];
                return;
            } else {
                RCDebugLog(RCStrings.network.starting_request, httpMethod, path);
                self.currentSerialRequest = rcRequest;
            }
        }
    }


    typedef void (^SessionCompletionBlock)(NSData *_Nullable, NSURLResponse *_Nullable, NSError *_Nullable);

    SessionCompletionBlock block = ^void(NSData *_Nullable data,
                                         NSURLResponse *_Nullable response,
                                         NSError *_Nullable error) {
        [self handleResponse:response
                        data:data
                       error:error
                     request:urlRequest
           completionHandler:completionHandler
beginNextRequestWhenFinished:performSerially];
    };

    RCDebugLog(RCStrings.network.api_request_started, urlRequest.HTTPMethod, urlRequest.URL.path);
    NSURLSessionTask *task = [self.session dataTaskWithRequest:urlRequest
                                             completionHandler:block];
    [task resume];
}

- (void)      handleResponse:(NSURLResponse *)response
                        data:(NSData *)data
                       error:(NSError *)error
                     request:(NSMutableURLRequest *)request
           completionHandler:(RCHTTPClientResponseHandler)completionHandler
beginNextRequestWhenFinished:(BOOL)beginNextRequestWhenFinished {
    NSInteger statusCode = RC_NETWORK_CONNECT_TIMEOUT_ERROR;
    NSDictionary *responseObject = nil;

    if (error == nil) {
        statusCode = ((NSHTTPURLResponse *) response).statusCode;

        RCDebugLog(RCStrings.network.api_request_completed, request.HTTPMethod, request.URL.path, (long)statusCode);

        NSError *jsonError;
        responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:&jsonError];

        if (jsonError) {
            RCErrorLog(RCStrings.network.parsing_json_error, jsonError.localizedDescription);
            RCErrorLog(RCStrings.network.json_data_received, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            error = jsonError;
        }
    }

    if (completionHandler != nil) {
        completionHandler(statusCode, responseObject, error);
    }

    if (beginNextRequestWhenFinished) {
        @synchronized (self) {
            RCDebugLog(RCStrings.network.serial_request_done,
                       self.currentSerialRequest.httpMethod,
                       self.currentSerialRequest.path,
                       (unsigned long)self.queuedRequests.count);
            RCHTTPRequest *nextRequest = nil;
            self.currentSerialRequest = nil;
            if (self.queuedRequests.count > 0) {
                nextRequest = self.queuedRequests[0];
                [self.queuedRequests removeObjectAtIndex:0];
            }
            if (nextRequest) {
                RCDebugLog(RCStrings.network.starting_next_request, nextRequest);
                [self performRequest:nextRequest.httpMethod
                            serially:YES
                                path:nextRequest.path
                                body:nextRequest.requestBody
                             headers:nextRequest.headers
                   completionHandler:nextRequest.completionHandler];
            }
        }
    }
}

- (nullable NSMutableURLRequest *)createRequestWithMethod:(NSString *)httpMethod
                                                     path:(NSString *)path
                                              requestBody:(NSDictionary *)requestBody
                                                  headers:(NSMutableDictionary *)defaultHeaders {
    NSString *relativeURLString = [NSString stringWithFormat:@"/v1%@", path];
    NSURL *requestURL = [NSURL URLWithString:relativeURLString relativeToURL:RCSystemInfo.serverHostURL];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];

    request.HTTPMethod = httpMethod;
    request.allHTTPHeaderFields = defaultHeaders;

    if ([httpMethod isEqualToString:@"POST"]) {
        NSError *jsonParseError;
        NSData *body;
        BOOL isValidJSONObject = [NSJSONSerialization isValidJSONObject:requestBody];
        if (isValidJSONObject) {
            body = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&jsonParseError];
        }
        if (!isValidJSONObject || jsonParseError) {
            RCErrorLog(RCStrings.network.creating_json_error, requestBody);
            return nil;
        }
        request.HTTPBody = body;
    }
    return request;
}

- (void)assertIsValidRequestWithMethod:(NSString *)HTTPMethod body:(NSDictionary *)requestBody {
    NSParameterAssert(([HTTPMethod isEqualToString:@"GET"] || [HTTPMethod isEqualToString:@"POST"]));
    NSParameterAssert(!([HTTPMethod isEqualToString:@"GET"] && requestBody));
    NSParameterAssert(!([HTTPMethod isEqualToString:@"POST"] && !requestBody));
}

- (NSDictionary *)defaultHeaders {
    NSString *observerMode = [NSString stringWithFormat:@"%@", self.systemInfo.finishTransactions ? @"false" : @"true"];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    [headers addEntriesFromDictionary: @{
        @"content-type": @"application/json",
        @"X-Version": RCSystemInfo.frameworkVersion,
        @"X-Platform": RCSystemInfo.platformHeader,
        @"X-Platform-Version": RCSystemInfo.systemVersion,
        @"X-Platform-Flavor": self.systemInfo.platformFlavor,
        @"X-Client-Version": RCSystemInfo.appVersion,
        @"X-Client-Build-Version": RCSystemInfo.buildVersion,
        @"X-Observer-Mode-Enabled": observerMode
    }];

    NSString * _Nullable platformFlavorVersion = self.systemInfo.platformFlavorVersion;
    if (platformFlavorVersion) {
        headers[@"X-Platform-Flavor-Version"] = platformFlavorVersion;
    }

    NSString * _Nullable idfv = RCSystemInfo.identifierForVendor;
    if (idfv) {
        headers[@"X-Apple-Device-Identifier"] = idfv;
    }

    return headers;
}


@end


NS_ASSUME_NONNULL_END
