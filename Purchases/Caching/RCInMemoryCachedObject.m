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
@property (nonatomic, nullable) id cachedInstance;

@end


@implementation RCInMemoryCachedObject

- (BOOL)isCacheStaleWithDurationInSeconds:(int)durationInSeconds {
    if (self.lastUpdatedAt == nil) {
        return YES;
    }

    NSTimeInterval timeSinceLastCheck = -1 * [self.lastUpdatedAt timeIntervalSinceNow];
    return timeSinceLastCheck >= durationInSeconds;
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

- (void)cacheInstance:(id<NSObject>)instance {
    @synchronized (self) {
        self.cachedInstance = instance;
        self.lastUpdatedAt = [NSDate date];
    }
}

- (void)updateCacheTimestampWithDate:(NSDate *)date {
    self.lastUpdatedAt = date;
}

@end


NS_ASSUME_NONNULL_END
