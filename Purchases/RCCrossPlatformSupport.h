//
//  RCCrossPlatformSupport.h
//  Purchases
//
//  Created by Jacob Eiting on 5/24/18.
//  Copyright © 2019 RevenueCat, Inc. All rights reserved.
//
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME UIApplicationDidBecomeActiveNotification
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME NSApplicationDidBecomeActiveNotification
#endif
#if TARGET_OS_UIKITFORMAC
#define PLATFORM_HEADER @"uikitformac"
#elif TARGET_OS_IPHONE
#define PLATFORM_HEADER @"iOS"
#elif TARGET_OS_MAC
#define PLATFORM_HEADER @"macOS"
#endif
