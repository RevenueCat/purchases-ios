//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSystemInfo.h"
#import "RCCrossPlatformSupport.h"
#import "RCLogUtils.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo()

@property(nonatomic, copy, nullable) NSString *platformFlavor;
@property(nonatomic, copy, nullable) NSString *platformFlavorVersion;

@end

@implementation RCSystemInfo

NSString *const defaultServerHostName = @"https://api.revenuecat.com";
static NSURL * _Nullable proxyURL;
static BOOL _forceUniversalAppStore = NO;

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                 platformFlavorVersion:(nullable NSString *)platformFlavorVersion
                    finishTransactions:(BOOL)finishTransactions {
    if (self = [super init]) {
        NSAssert((platformFlavor && platformFlavorVersion) || (!platformFlavor && !platformFlavorVersion),
            @"RCSystemInfo initialized with non-matching platform flavor and platform flavor versions!");

        if (!platformFlavor) {
            platformFlavor = @"native";
        }

        self.platformFlavor = platformFlavor;
        self.platformFlavorVersion = platformFlavorVersion;
        self.finishTransactions = finishTransactions;
    }
    return self;
}

+ (BOOL)isSandbox {
    NSURL *url = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *receiptURLString = url.path;
    return ([receiptURLString rangeOfString:@"sandboxReceipt"].location != NSNotFound);
}

+ (NSString *)frameworkVersion {
    return @"3.7.4";
}

+ (NSString *)systemVersion {
    NSProcessInfo *info = [[NSProcessInfo alloc] init];
    return info.operatingSystemVersionString;
}

+ (NSString *)appVersion {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return version ?: @"";
}

+ (NSString *)platformHeader {
    return self.forceUniversalAppStore ? @"iOS" : PLATFORM_HEADER;
}

+ (NSURL *)defaultServerHostURL {
    return [NSURL URLWithString:defaultServerHostName];
}

+ (NSURL *)serverHostURL {
    return proxyURL ?: self.defaultServerHostURL;
}

+ (nullable NSURL *)proxyURL {
    return proxyURL;
}

+ (BOOL)forceUniversalAppStore {
    return _forceUniversalAppStore;
}

+ (void)setForceUniversalAppStore:(BOOL)forceUniversalAppStore {
    _forceUniversalAppStore = forceUniversalAppStore;
}

+ (void)setProxyURL:(nullable NSURL *)newProxyURL {
    proxyURL = newProxyURL;
    if (newProxyURL) {
        RCLog(@"Purchases is being configured using a proxy for RevenueCat with URL: %@", newProxyURL);
    }
}

- (void)isApplicationBackgroundedWithCompletion:(void(^)(BOOL))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isApplicationBackgrounded = self.isApplicationBackgrounded;
        completion(isApplicationBackgrounded);
    });
}

- (BOOL)isApplicationBackgrounded {
#if TARGET_OS_IOS
    return self.isApplicationBackgroundedIOS;
#elif TARGET_OS_TV
    return  UIApplication.sharedApplication.applicationState == UIApplicationStateBackground;
#elif TARGET_OS_OSX
    return  NO;
#elif TARGET_OS_WATCH
    return  WKExtension.sharedExtension.applicationState == WKApplicationStateBackground;
#endif
}

#if TARGET_OS_IOS
// iOS App extensions can't access UIApplication.sharedApplication, and will fail to compile if any calls to
// it are made. There are no pre-processor macros available to check if the code is running in an app extension,
// so we check if we're running in an app extension at runtime, and if not, we use KVC to call sharedApplication. 
- (BOOL)isApplicationBackgroundedIOS {
    if (self.isAppExtension) {
        return YES;
    }
    NSString *sharedApplicationPropertyName = @"sharedApplication";

    UIApplication *sharedApplication = [UIApplication valueForKey:sharedApplicationPropertyName];
    return sharedApplication.applicationState == UIApplicationStateBackground;
}

- (BOOL)isAppExtension {
    return [NSBundle.mainBundle.bundlePath hasSuffix:@".appex"];
}

#endif

@end


NS_ASSUME_NONNULL_END
