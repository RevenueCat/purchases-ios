//
//  RCCachedObjectInfo.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2020 Purchases. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "RCCachedObjectInfo.h"

NS_ASSUME_NONNULL_BEGIN


@interface RCCachedObjectInfo ()

@property (nonatomic, nullable) NSDate *lastUpdatedAt;
@property (nonatomic, assign) int cacheDurationInSeconds;

@end


NS_ASSUME_NONNULL_END


@implementation RCCachedObjectInfo

- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds {
    return [self initWithCacheDurationInSeconds:cacheDurationInSeconds
                                  lastUpdatedAt:nil];
}
- (instancetype)initWithCacheDurationInSeconds:(int)cacheDurationInSeconds
                                 lastUpdatedAt:(NSDate *_Nullable)lastUpdatedAt {
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

- (void)updateCacheTimestampToNow {
    [self updateCacheTimestampWithDate:[NSDate date]];
}

- (void)updateCacheTimestampWithDate:(NSDate *)date {
    self.lastUpdatedAt = date;
}

@end
