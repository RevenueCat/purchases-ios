//
//  RCAttributionFetcher.m
//  Purchases
//
//  Created by César de la Vega  on 4/17/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCAttributionFetcher.h"
#import <AdSupport/AdSupport.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#endif

@implementation RCAttributionFetcher : NSObject

- (NSString * _Nullable)advertisingIdentifier
{
    if (@available(iOS 6.0, macOS 10.14, *)) {
        if ([ASIdentifierManager class]) {
            return ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;
        }
    }
    return nil;
}


- (NSString * _Nullable)identifierForVendor
{
#if TARGET_OS_IPHONE
    if ([UIDevice class]) {
        return UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
#endif
    return nil;
}

- (void)adClientAttributionDetailsWithBlock:(void (^)(NSDictionary<NSString *, NSObject *> * _Nullable attributionDetails, NSError * _Nullable error))completionHandler
{
#if TARGET_OS_IPHONE
    if ([ADClient class]) {
        [ADClient.sharedClient requestAttributionDetailsWithBlock:completionHandler];
    }
#endif
}

@end

