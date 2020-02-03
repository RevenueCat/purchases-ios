//
//  RCInMemoryCachedObject.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "RCInMemoryCachedObject.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCInMemoryCachedObject ()

@property (nonatomic, nullable) NSDate *lastUpdatedAt;
@property (nonatomic, assign) int cacheDurationInSeconds;
@property (nonatomic, nullable) id cachedInstance;

@end


@implementation RCInMemoryCachedObject

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds {
    return [self initWithCacheDurationInSeconds:cacheDurationInSeconds
                                  lastUpdatedAt:nil];
}

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(nullable NSDate *)lastUpdatedAt {
    if (self == [super init]) {
        self.cacheDurationInSeconds = cacheDurationInSeconds;
        self.lastUpdatedAt = lastUpdatedAt;
    }
    return self;
}

- (BOOL)isCacheStale {
    if (self.lastUpdatedAt == nil) {
        return YES;
    }

    NSTimeInterval timeSinceLastCheck = -1 * [self.lastUpdatedAt timeIntervalSinceNow];
    return timeSinceLastCheck >= self.cacheDurationInSeconds;
}

- (void)clearCacheTimestamp {
    self.lastUpdatedAt = nil;
}

- (void)clearCache {
    [self clearCacheTimestamp];
    self.cachedInstance = nil;
}

- (void)cacheInstance:(id)instance date:(NSDate *)date {
    self.cachedInstance = instance;
    self.lastUpdatedAt = date;
}

- (void)updateCacheTimestampWithDate:(NSDate *)date {
    self.lastUpdatedAt = date;
}

@end


NS_ASSUME_NONNULL_END
