//
//  RCPurchaserInfo.m
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2017 RevenueCat, Inc. All rights reserved.
//

#import "RCPurchaserInfo.h"

@interface RCPurchaserInfo ()

@property (nonatomic) NSDictionary<NSString *, NSDate *> *expirationDates;
@property (nonatomic) NSSet<NSString *> *nonConsumablePurchases;
@property (nonatomic) NSString *originalApplicationVersion;

@end

static NSDateFormatter *dateFormatter;
static dispatch_once_t onceToken;

@implementation RCPurchaserInfo

- (instancetype _Nullable)initWithData:(NSDictionary *)data
{
    if (self == [super init]) {
        if (data[@"subscriber"] == nil) {
            return nil;
        }

        NSDictionary *subscriberData = data[@"subscriber"];

        dispatch_once(&onceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        });
        
        NSMutableDictionary<NSString *, NSDate *> *dates = [NSMutableDictionary new];

        NSDictionary *subscriptions = subscriberData[@"subscriptions"];
        if (subscriptions == nil) {
            return nil;
        }

        for (NSString *productID in subscriptions) {
            NSString *dateString = subscriptions[productID][@"expires_date"];
            NSDate *date = [dateFormatter dateFromString:dateString];

            if (date == nil) {
                return nil;
            }

            dates[productID] = date;
        }

        self.expirationDates = [NSDictionary dictionaryWithDictionary:dates];

        NSDictionary<NSString *, id> *otherPurchases = subscriberData[@"other_purchases"];
        self.nonConsumablePurchases = [NSSet setWithArray:[otherPurchases allKeys]];

        self.originalApplicationVersion = subscriberData[@"original_application_version"];

    }
    return self;
}

- (NSSet<NSString *> *)allPurchasedProductIdentifiers
{
    return [self.nonConsumablePurchases setByAddingObjectsFromArray:self.expirationDates.allKeys];
}

- (NSSet<NSString *> *)activeSubscriptions
{
    NSMutableSet *activeSubscriptions = [NSMutableSet setWithCapacity:self.expirationDates.count];

    for (NSString *productIdentifier in self.expirationDates) {
        if (self.expirationDates[productIdentifier].timeIntervalSinceNow > 0) {
            [activeSubscriptions addObject:productIdentifier];
        }
    }
    
    return [NSSet setWithSet:activeSubscriptions];
}

- (NSDate * _Nullable)latestExpirationDate
{
    NSDate *maxDate = nil;

    for (NSDate *date in self.expirationDates.allValues) {
        if (date.timeIntervalSince1970 > maxDate.timeIntervalSince1970) {
            maxDate = date;
        }
    }

    return maxDate;
}

- (NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier
{
    return self.expirationDates[productIdentifier];
}

@end
