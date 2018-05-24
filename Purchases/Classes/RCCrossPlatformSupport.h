//
//  RCCrossPlatformSupport.h
//  Purchases
//
//  Created by Jacob Eiting on 5/24/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME UIApplicationDidBecomeActiveNotification
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#define APP_DID_BECOME_ACTIVE_NOTIFICATION_NAME NSApplicationDidBecomeActiveNotification
#endif
