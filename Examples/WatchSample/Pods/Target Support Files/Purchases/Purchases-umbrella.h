#ifdef __OBJC__
#import <Foundation/Foundation.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Purchases.h"
#import "RCEntitlementInfo.h"
#import "RCEntitlementInfos.h"
#import "RCIntroEligibility.h"
#import "RCOffering.h"
#import "RCOfferings.h"
#import "RCPackage.h"
#import "RCPurchaserInfo.h"
#import "RCPurchases.h"
#import "RCPurchasesErrors.h"
#import "RCPurchasesErrorUtils.h"

FOUNDATION_EXPORT double PurchasesVersionNumber;
FOUNDATION_EXPORT const unsigned char PurchasesVersionString[];

