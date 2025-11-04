//
//  RCAdTrackerAPI.h
//  ObjCAPITester
//
//  Created by RevenueCat on 1/20/25.
//

#import <Foundation/Foundation.h>

#ifdef ENABLE_AD_EVENTS_TRACKING

NS_ASSUME_NONNULL_BEGIN

@interface RCAdTrackerAPI : NSObject

+ (void)checkAPI;

@end

NS_ASSUME_NONNULL_END

#endif
