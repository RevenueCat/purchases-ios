//
//  RCInMemoryCachedObject.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "RCInMemoryCachedObject.h"
#import "RCInMemoryCachedObject+Protected.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCInMemoryCachedObject ()

@property (nonatomic, nullable) NSDate *lastUpdatedAt;
@property (nonatomic, assign) int cacheDurationInSeconds;
@property (nonatomic, nullable) id cachedInstance;

@property (nonatomic, nullable) NSDate *stubbedNow;

@end


@implementation RCInMemoryCachedObject

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds {
    return [self initWithCacheDurationInSeconds:cacheDurationInSeconds
                                  lastUpdatedAt:nil];
}

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(nullable NSDate *)lastUpdatedAt {
    return [self initWithCacheDurationInSeconds:cacheDurationInSeconds
                                  lastUpdatedAt:lastUpdatedAt
                                     stubbedNow:nil];
}

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(nullable NSDate *)lastUpdatedAt
                                    stubbedNow:(nullable NSDate *)stubbedNow {
    if (self == [super init]) {
        self.cacheDurationInSeconds = cacheDurationInSeconds;
        self.lastUpdatedAt = lastUpdatedAt;
        self.stubbedNow = stubbedNow;
    }
    return self;
}

- (BOOL)isCacheStale {
    if (self.lastUpdatedAt == nil) {
        return YES;
    }

    NSTimeInterval timeSinceLastCheck = -1 * [self.lastUpdatedAt timeIntervalSinceDate:self.now];
    return timeSinceLastCheck >= self.cacheDurationInSeconds;
}

- (void)clearCacheTimestamp {
    self.lastUpdatedAt = nil;
}

- (void)clearCache {
    @synchronized(self) {
        [self clearCacheTimestamp];
        self.cachedInstance = nil;
    }
}

- (void)cacheInstance:(id)instance date:(NSDate *)date {
    @synchronized(self) {
        self.cachedInstance = instance;
        self.lastUpdatedAt = date;
    }
}

- (void)updateCacheTimestampWithDate:(NSDate *)date {
    self.lastUpdatedAt = date;
}

- (NSDate *)now {
    if (self.stubbedNow) {
        return self.stubbedNow;
    } else {
        return [NSDate date];
    }
}

@end


NS_ASSUME_NONNULL_END
