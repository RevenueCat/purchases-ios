//
//  RCInMemoryCachedObject.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface RCInMemoryCachedObject<ObjectType: id<NSObject>> : NSObject

- (BOOL)isCacheStale;

- (void)clearCacheTimestamp;

- (void)clearCache;

- (void)updateCacheTimestampWithDate:(NSDate *)date;

- (void)cacheInstance:(ObjectType)instance;

- (nullable ObjectType)cachedInstance;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds;

@end


NS_ASSUME_NONNULL_END
