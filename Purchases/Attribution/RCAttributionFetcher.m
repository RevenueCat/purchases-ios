//
//  RCAttributionFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

@import PurchasesCoreSwift;

#import "RCAttributionFetcher.h"
#import "RCIdentityManager.h"
#import "RCBackend.h"

static NSMutableArray<RCAttributionData *> *_Nullable postponedAttributionData;

@interface RCAttributionFetcher ()

@property (strong, nonatomic) RCDeviceCache *deviceCache;
@property (strong, nonatomic) RCIdentityManager *identityManager;
@property (strong, nonatomic) RCBackend *backend;
@property (strong, nonatomic) RCAttributionTypeFactory *attributionFactory;
@property (strong, nonatomic) RCSystemInfo *systemInfo;

@end

@implementation RCAttributionFetcher : NSObject

- (instancetype)initWithDeviceCache:(RCDeviceCache *)deviceCache
                    identityManager:(RCIdentityManager *)identityManager
                            backend:(RCBackend *)backend
                 attributionFactory:(RCAttributionTypeFactory *)attributionFactory
                         systemInfo:(RCSystemInfo *)systemInfo {
    if (self = [super init]) {
        self.deviceCache = deviceCache;
        self.identityManager = identityManager;
        self.backend = backend;
        self.attributionFactory = attributionFactory;
        self.systemInfo = systemInfo;
    }
    return self;
}

- (nullable NSString *)identifierForAdvertisers {
    if (@available(iOS 6.0, macOS 10.14, *)) {
        RCASIdentifierManagerProxy * _Nullable asIdentifierProxy = [self.attributionFactory asIdentifierProxy];
        if (asIdentifierProxy) {
            NSUUID * _Nullable identifierValue = [asIdentifierProxy adsIdentifier];
            if (identifierValue) {
                return identifierValue.UUIDString;
            }
        } else {
            [RCLog warn:[NSString stringWithFormat:@"%@", RCStrings.configure.adsupport_not_imported]];
        }
    }
    return nil;
}

- (nullable NSString *)identifierForVendor {
    // Should match available platforms in
    // https://developer.apple.com/documentation/uikit/uidevice?language=objc
    #if TARGET_OS_IOS || TARGET_OS_TV
    if ([UIDevice class]) {
        return UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
    #endif
    return nil;
}

- (void)adClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler {
    // Should match available platforms in
    // https://developer.apple.com/documentation/iad/adclient?language=objc
    #if TARGET_OS_IOS
    RCAdClientProxy * _Nullable adClientProxy = [self.attributionFactory adClientProxy];
    if (!adClientProxy) {
        [RCLog warn:[NSString stringWithFormat:@"%@",
                     RCStrings.attribution.search_ads_attribution_cancelled_missing_iad_framework]];
        return;
    }
    [adClientProxy requestAttributionDetailsWithBlock:completionHandler];
    #endif
}

- (BOOL)isAuthorizedToPostSearchAds {
    // Should match platforms that require permissions detailed in
    // https://developer.apple.com/app-store/user-privacy-and-data-use/
    #if !TARGET_OS_WATCH && !TARGET_OS_OSX && !TARGET_OS_MACCATALYST
    if (@available(iOS 14, macos 11, tvos 14, *)) {
        NSOperatingSystemVersion minimumOSVersionRequiringAuthorization = { .majorVersion = 14, .minorVersion = 5, .patchVersion = 0 };

        BOOL needsTrackingAuthorization = [self.systemInfo isOperatingSystemAtLeastVersion:minimumOSVersionRequiringAuthorization];

        RCTrackingManagerProxy * _Nullable trackingProxy = [self.attributionFactory atTrackingProxy];
        if (!trackingProxy) {
            if (needsTrackingAuthorization) {
                [RCLog warn:[NSString stringWithFormat:@"%@",
                             RCStrings.attribution.search_ads_attribution_cancelled_missing_att_framework]];
            }
            return !needsTrackingAuthorization;
        }
        
        SEL authStatusSelector = NSSelectorFromString(trackingProxy.authorizationStatusPropertyName);
        BOOL canPerformSelector = [trackingProxy respondsToSelector:authStatusSelector];
        if (!canPerformSelector) {
            [RCLog warn:[NSString stringWithFormat:@"%@",
                         RCStrings.attribution.att_framework_present_but_couldnt_call_tracking_authorization_status]];
            return NO;
        }
        // we use NSInvocation to prevent direct references to tracking frameworks, which cause issues for
        // kids apps when going through app review, even if they don't actually use them at all. 
        NSMethodSignature *methodSignature = [trackingProxy methodSignatureForSelector:authStatusSelector];
        NSInvocation *myInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [myInvocation setTarget:trackingProxy];
        [myInvocation setSelector:authStatusSelector];

        [myInvocation invoke];
        NSInteger authorizationStatus;
        [myInvocation getReturnValue:&authorizationStatus];

        BOOL authorized = authorizationStatus == FakeTrackingManagerAuthorizationStatusAuthorized
                          || (!needsTrackingAuthorization
                              && authorizationStatus == FakeTrackingManagerAuthorizationStatusNotDetermined);
        if (!authorized) {
            [RCLog info:[NSString stringWithFormat:@"%@",
                         RCStrings.attribution.search_ads_attribution_cancelled_not_authorized]];
            return NO;
        }

    }
    #endif
    return YES;
}

@end

