//
//  RCOtherAPI.m
//  ObjCAPITester
//
//  Created by Nacho Soto on 6/12/23.
//

@import RevenueCat;
@import UIKit;

#import "RCOtherAPI.h"

@implementation RCOtherAPI

+ (void)checkAPI {
    #if DEBUG
    if (@available(iOS 16.0, *)) {
        RCDebugViewController *controller = [RCDebugViewController new];

        [UIViewController.new rc_presentDebugRevenueCatOverlayAnimated:NO];
    }
    #endif
}

@end
