//
// Created by Andrés Boedo on 5/7/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "RCSystemInfo.h"
#import "RCCrossPlatformSupport.h"
#import "RCLogUtils.h"
@import PurchasesCoreSwift;

NS_ASSUME_NONNULL_BEGIN


@interface RCSystemInfo()

@property(nonatomic, copy, nullable) NSString *platformFlavor;
@property(nonatomic, copy, nullable) NSString *platformFlavorVersion;
@property(nonatomic, readwrite) RCDangerousSettings *dangerousSettings;

@end

@implementation RCSystemInfo

NSString *const defaultServerHostName = @"https://api.revenuecat.com";
static NSURL * _Nullable proxyURL;
static BOOL _forceUniversalAppStore = NO;

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                 platformFlavorVersion:(nullable NSString *)platformFlavorVersion
                    finishTransactions:(BOOL)finishTransactions {
    return [self initWithPlatformFlavor:platformFlavor
                  platformFlavorVersion:platformFlavorVersion
                     finishTransactions:finishTransactions
                      dangerousSettings:nil];
}

- (instancetype)initWithPlatformFlavor:(nullable NSString *)platformFlavor
                 platformFlavorVersion:(nullable NSString *)platformFlavorVersion
                    finishTransactions:(BOOL)finishTransactions
                     dangerousSettings:(nullable RCDangerousSettings *)dangerousSettings {
    if (self = [super init]) {
        NSAssert((platformFlavor && platformFlavorVersion) || (!platformFlavor && !platformFlavorVersion),
            @"RCSystemInfo initialized with non-matching platform flavor and platform flavor versions!");

        if (!platformFlavor) {
            platformFlavor = @"native";
        }

        self.platformFlavor = platformFlavor;
        self.platformFlavorVersion = platformFlavorVersion;
        self.finishTransactions = finishTransactions;
        if (!dangerousSettings) {
            dangerousSettings = [[RCDangerousSettings alloc] init];
        }
        self.dangerousSettings = dangerousSettings;
    }
    return self;
}

+ (BOOL)isSandbox {
    NSURL *url = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *receiptURLString = url.path;
    return ([receiptURLString rangeOfString:@"sandboxReceipt"].location != NSNotFound);
}

+ (NSString *)frameworkVersion {
    return @"3.14.2";
}

+ (NSString *)systemVersion {
    NSProcessInfo *info = [[NSProcessInfo alloc] init];
    return info.operatingSystemVersionString;
}

+ (NSString *)appVersion {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return version ?: @"";
}

+ (NSString *)buildVersion {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
    return version ?: @"";
}

+ (NSString *)platformHeader {
    return self.forceUniversalAppStore ? @"iOS" : PLATFORM_HEADER;
}

+ (nullable NSString *)identifierForVendor {
#if UI_DEVICE_AVAILABLE
    return UIDevice.currentDevice.identifierForVendor.UUIDString;
#elif WKINTERFACE_DEVICE_AVAILABLE
    return WKInterfaceDevice.currentDevice.identifierForVendor.UUIDString;
#endif
    return nil;
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
        RCLog(RCStrings.configure.configuring_purchases_proxy_url_set, newProxyURL);
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

- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version {
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:version];
}

@end


NS_ASSUME_NONNULL_END
