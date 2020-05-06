//
//  RCHTTPClient.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCHTTPClient.h"
#import "RCUtils.h"
#import "RCPurchases.h"
#import "RCCrossPlatformSupport.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *overrideHostName = nil;

void RCOverrideServerHost(NSString *hostname) {
    overrideHostName = hostname;
}


@interface RCHTTPClient ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSString *platformFlavor;

@end


@implementation RCHTTPClient

+ (NSString *)serverHostName {
    return (overrideHostName) ? overrideHostName : @"api.revenuecat.com";
}

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.HTTPMaximumConnectionsPerHost = 1;
        self.session = [NSURLSession sessionWithConfiguration:config];
        self.platformFlavor = platformFlavor;
    }
    return self;
}

+ (NSString *)systemVersion {
    NSProcessInfo *info = [[NSProcessInfo alloc] init];
    return info.operatingSystemVersionString;
}

+ (NSString *)appVersion {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    if (version) {
        return version;
    } else {
        return @"";
    }
}

- (void)performRequest:(NSString *)HTTPMethod
                  path:(NSString *)path
                  body:(nullable NSDictionary *)requestBody
               headers:(nullable NSDictionary<NSString *, NSString *> *)headers
     completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler {
    [self assertIsValidRequestWithMethod:HTTPMethod body:requestBody];

    NSMutableDictionary *defaultHeaders = self.defaultHeaders.mutableCopy;
    [defaultHeaders addEntriesFromDictionary:headers];

    NSMutableURLRequest *request = [self createRequestWithMethod:HTTPMethod
                                                            path:path
                                                     requestBody:requestBody
                                                         headers:defaultHeaders];

    typedef void (^SessionCompletionBlock)(NSData *_Nullable, NSURLResponse *_Nullable, NSError *_Nullable);

    SessionCompletionBlock block = ^void(NSData *_Nullable data,
                                         NSURLResponse *_Nullable response,
                                         NSError *_Nullable error) {
        [self handleResponse:response data:data error:error request:request completionHandler:completionHandler];
    };

    RCDebugLog(@"%@ %@", request.HTTPMethod, request.URL.path);
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:block];
    [task resume];
}

- (void)handleResponse:(NSURLResponse *)response
                  data:(NSData *)data
                 error:(NSError *)error
               request:(NSMutableURLRequest *)request
     completionHandler:(RCHTTPClientResponseHandler)completionHandler {
    NSInteger statusCode = 599;
    NSDictionary *responseObject = nil;

    if (error == nil) {
        statusCode = ((NSHTTPURLResponse *) response).statusCode;

        RCDebugLog(@"%@ %@ %d", request.HTTPMethod, request.URL.path, statusCode);

        NSError *jsonError;
        responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:&jsonError];

        if (jsonError) {
            RCLog(@"Error parsing JSON %@", jsonError.localizedDescription);
            RCLog(@"Data received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            error = jsonError;
        }
    }

    if (completionHandler != nil) {
        completionHandler(statusCode, responseObject, error);
    }
}

- (NSMutableURLRequest *)createRequestWithMethod:(NSString *)HTTPMethod
                                            path:(NSString *)path
                                     requestBody:(NSDictionary *)requestBody
                                         headers:(NSMutableDictionary *)defaultHeaders {
    NSString *urlString = [NSString stringWithFormat:@"https://%@/v1%@", self.class.serverHostName, path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];

    request.HTTPMethod = HTTPMethod;
    request.allHTTPHeaderFields = defaultHeaders;

    if ([HTTPMethod isEqualToString:@"POST"]) {
        NSError *JSONParseError;
        NSData *body = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:&JSONParseError];
        if (JSONParseError) {
            RCLog(@"Error creating request JSON: %@", requestBody);
        }
        request.HTTPBody = body;
    }
    return request;
}

- (void)assertIsValidRequestWithMethod:(NSString *)HTTPMethod body:(NSDictionary *)requestBody {
    NSParameterAssert(!([HTTPMethod isEqualToString:@"GET"] && requestBody));
    NSParameterAssert(([HTTPMethod isEqualToString:@"GET"] || [HTTPMethod isEqualToString:@"POST"]));
}

- (NSDictionary *)defaultHeaders {
    return [NSMutableDictionary
        dictionaryWithDictionary:@{@"content-type": @"application/json",
            @"X-Version": RCPurchases.frameworkVersion,
            @"X-Platform": PLATFORM_HEADER,
            @"X-Platform-Version": self.class.systemVersion,
            @"X-Platform-Flavor": self.platformFlavor ?: @"native",
            @"X-Client-Version": self.class.appVersion}];
}


@end


NS_ASSUME_NONNULL_END
