//
//  RCInMemoryCachedObject.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN


@interface RCInMemoryCachedObject<ObjectType> : NSObject

- (BOOL)isCacheStale;
- (void)clearCacheTimestamp;
- (void)clearCache;
- (void)updateCacheTimestampWithDate:(NSDate *)date;
- (void)cacheInstance:(ObjectType)instance
                 date:(NSDate *)date;
- (ObjectType _Nullable)cachedInstance;

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds;

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(NSDate *_Nullable)lastUpdatedAt;
@end


NS_ASSUME_NONNULL_END
