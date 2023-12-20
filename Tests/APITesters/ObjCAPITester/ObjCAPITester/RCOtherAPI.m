//
//  RCOtherAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 6/12/23.
//

@import RevenueCat;

#if TARGET_OS_IPHONE
@import UIKit;
#endif

#import "RCOtherAPI.h"

@implementation RCOtherAPI

+ (void)checkAPI {
    #if DEBUG && TARGET_OS_IPHONE && defined(__IPHONE_17_0)
    if (@available(iOS 16.0, *)) {
        RCDebugViewController *controller __unused = [RCDebugViewController new];

        [UIViewController.new rc_presentDebugRevenueCatOverlayAnimated:NO];
    }
    #endif
}

@end
