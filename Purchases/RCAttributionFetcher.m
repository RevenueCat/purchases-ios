//
//  RCAttributionFetcher.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCAttributionFetcher.h"
#import "RCUtils.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@protocol FakeAdClient <NSObject>

+ (instancetype)sharedClient;
- (void)requestAttributionDetailsWithBlock:(void (^)(NSDictionary<NSString *, NSObject *> * _Nullable attributionDetails, NSError * _Nullable error))completionHandler;

@end

@protocol FakeASIdentifierManager <NSObject>

@property (nonnull, nonatomic, readonly) NSUUID *advertisingIdentifier;

+ (instancetype)sharedManager;

@end

@implementation RCAttributionFetcher : NSObject

- (nullable NSString *)advertisingIdentifier
{
    if (@available(iOS 6.0, macOS 10.14, *)) {
        id<FakeASIdentifierManager> asIdentifierManagerClass = (id<FakeASIdentifierManager>)NSClassFromString(@"ASIdentifierManager");
        if (asIdentifierManagerClass) {
            return [asIdentifierManagerClass sharedManager].advertisingIdentifier.UUIDString;
        } else {
            RCDebugLog(@"AdSupport framework not imported. Attribution data incomplete.");
        }
    }
    return nil;
}


- (nullable NSString *)identifierForVendor
{
#if TARGET_OS_IOS || TARGET_OS_TV
    if ([UIDevice class]) {
        return UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
#endif
    return nil;
}

- (void)adClientAttributionDetailsWithCompletionBlock:(void (^)(NSDictionary<NSString *, NSObject *> * _Nullable attributionDetails, NSError * _Nullable error))completionHandler
{
#if TARGET_OS_IOS
    id<FakeAdClient> adClientClass = (id<FakeAdClient>)NSClassFromString(@"ADClient");
    
    if (adClientClass) {
        [[adClientClass sharedClient] requestAttributionDetailsWithBlock:completionHandler];
    }
#endif
}

@end

