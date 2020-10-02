//
//  RCInMemoryCachedObject.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface RCInMemoryCachedObject<ObjectType: id<NSObject>> : NSObject

- (BOOL)isCacheStaleWithDurationInSeconds:(int)durationInSeconds;

- (void)clearCacheTimestamp;

- (void)clearCache;

- (void)updateCacheTimestampWithDate:(NSDate *)date;

- (void)cacheInstance:(ObjectType)instance;

- (nullable ObjectType)cachedInstance;

@end


NS_ASSUME_NONNULL_END
