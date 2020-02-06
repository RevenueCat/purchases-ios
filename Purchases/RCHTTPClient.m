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

static NSString *overrideHostName = nil;

void RCOverrideServerHost(NSString *hostname)
{
    overrideHostName = hostname;
}

@interface RCHTTPClient ()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSString *platformFlavor;

@end

@implementation RCHTTPClient

+ (NSString *)serverHostName
{
    return  (overrideHostName) ? overrideHostName : @"api.revenuecat.com";
}

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
{
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
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
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
     completionHandler:(nullable RCHTTPClientResponseHandler)completionHandler
{
    NSParameterAssert(!([HTTPMethod isEqualToString:@"GET"] && requestBody));
    NSParameterAssert(([HTTPMethod isEqualToString:@"GET"] || [HTTPMethod isEqualToString:@"POST"]));

    NSString *urlString = [NSString stringWithFormat:@"https://%@/v1%@", self.class.serverHostName, path];

    NSMutableDictionary *defaultHeaders = [NSMutableDictionary
                                           dictionaryWithDictionary:@{@"content-type": @"application/json",
                                                                      @"X-Version": [RCPurchases frameworkVersion],
                                                                      @"X-Platform": PLATFORM_HEADER,
                                                                      @"X-Platform-Version": [self.class systemVersion],
                                                                      @"X-Platform-Flavor": self.platformFlavor ? self.platformFlavor : @"native",
                                                                      @"X-Client-Version": [self.class appVersion]}];
    [defaultHeaders addEntriesFromDictionary:headers];

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

    typedef void (^SessionCompletionBlock)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable);

    SessionCompletionBlock block = ^void(NSData * _Nullable data,
                                         NSURLResponse * _Nullable response,
                                         NSError * _Nullable error)
    {


        NSInteger statusCode = 599;
        NSDictionary *responseObject = nil;

        if (error == nil) {
            statusCode = ((NSHTTPURLResponse *)response).statusCode;

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
    };

    RCDebugLog(@"%@ %@", request.HTTPMethod, request.URL.path);

    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:block];
    [task resume];
}


@end
