//
//  RCAttributionFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCAttributionFetcher.h"
#import "RCCrossPlatformSupport.h"
#import "RCLogUtils.h"
#import "RCDeviceCache.h"
#import "RCIdentityManager.h"
#import "RCBackend.h"
#import "RCAttributionData.h"
#import "RCSystemInfo.h"
@import PurchasesCoreSwift;

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
        Class <FakeASIdManager> _Nullable asIdentifierManagerClass = [self.attributionFactory asIdClass];
        if (asIdentifierManagerClass) {
            id sharedManager = [asIdentifierManagerClass sharedManager];
            NSUUID *identifierValue = [sharedManager valueForKey:[self.attributionFactory asIdentifierPropertyName]];
            return identifierValue.UUIDString;
        } else {
            RCWarnLog(@"%@", RCStrings.configure.adsupport_not_imported);
        }
    }
    return nil;
}

- (nullable NSString *)identifierForVendor {
#if UI_DEVICE_AVAILABLE
    if ([UIDevice class]) {
        return UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
#endif
    return nil;
}

- (void)afficheClientAttributionDetailsWithCompletionBlock:(RCAttributionDetailsBlock)completionHandler {
#if AD_CLIENT_AVAILABLE
    Class<FakeAfficheClient> _Nullable afficheClientClass = [self.attributionFactory afficheClientClass];
    if (!afficheClientClass) {
        RCWarnLog(@"%@", RCStrings.attribution.search_ads_attribution_cancelled_missing_ad_framework);
        return;
    }
    [[afficheClientClass sharedClient] requestAttributionDetailsWithBlock:completionHandler];
#endif
}

- (BOOL)isAuthorizedToPostSearchAds {
#if APP_TRACKING_TRANSPARENCY_REQUIRED
    if (@available(iOS 14, macos 11, tvos 14, *)) {
        NSOperatingSystemVersion minimumOSVersionRequiringAuthorization = { .majorVersion = 14, .minorVersion = 5, .patchVersion = 0 };

        BOOL needsTrackingAuthorization = [self.systemInfo isOperatingSystemAtLeastVersion:minimumOSVersionRequiringAuthorization];

        Class _Nullable trackingManagerClass = [self.attributionFactory atFollowingClass];
        if (!trackingManagerClass) {
            if (needsTrackingAuthorization) {
                RCWarnLog(@"%@", RCStrings.attribution.search_ads_attribution_cancelled_missing_att_framework);
            }
            return !needsTrackingAuthorization;
        }
        SEL authStatusSelector = NSSelectorFromString(self.attributionFactory.authorizationStatusPropertyName);
        BOOL canPerformSelector = [trackingManagerClass respondsToSelector:authStatusSelector];
        if (!canPerformSelector) {
            RCWarnLog(@"%@", RCStrings.attribution.att_framework_present_but_couldnt_call_tracking_authorization_status);
            return NO;
        }
        // we use NSInvocation to prevent direct references to tracking frameworks, which cause issues for
        // kids apps when going through app review, even if they don't actually use them at all. 
        NSMethodSignature *methodSignature = [trackingManagerClass methodSignatureForSelector:authStatusSelector];
        NSInvocation *myInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [myInvocation setTarget:trackingManagerClass];
        [myInvocation setSelector:authStatusSelector];

        [myInvocation invoke];
        NSInteger authorizationStatus;
        [myInvocation getReturnValue:&authorizationStatus];

        BOOL authorized = authorizationStatus == FakeTrackingManagerAuthorizationStatusAuthorized
                          || (!needsTrackingAuthorization
                              && authorizationStatus == FakeTrackingManagerAuthorizationStatusNotDetermined);
        if (!authorized) {
            RCLog(@"%@", RCStrings.attribution.search_ads_attribution_cancelled_not_authorized);
            return NO;
        }

    }
#endif
    return YES;
}

@end

