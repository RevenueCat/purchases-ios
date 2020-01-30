//
//  RCCachedObjectInfo.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN


@interface RCCachedObjectInfo : NSObject

- (BOOL)isCacheStale;
- (void)clearCacheTimestamp;
- (void)updateCacheTimestampToNow;
- (void)updateCacheTimestampWithDate:(NSDate *)date;

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds;

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(NSDate *_Nullable)lastUpdatedAt;
@end


NS_ASSUME_NONNULL_END
