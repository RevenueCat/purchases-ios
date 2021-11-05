//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License [the "License"]
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerData.swift
//
//  Created by Joshua Liebowitz on 11/4/21.

import Foundation

struct CustomerData {

    let jsonString = """
 {
     "request_date": "2021-10-30T21:43:34Z",
     "request_date_ms": 1635630214094,
     "subscriber": {
         "entitlements": {
             "com.cinnamonmobile.StocksLiveFree.699_1m_1w0": {
                 "expires_date": "2021-05-23T19:13:46Z",
                 "grace_period_expires_date": null,
                 "product_identifier": "rc_promo_com.cinnamonmobile.StocksLiveFree.699_1m_1w0_monthly",
                 "purchase_date": "2021-04-22T19:13:46Z"
             }
         },
         "first_seen": "2020-08-09T19:04:14Z",
         "last_seen": "2021-10-29T22:12:32Z",
         "management_url": null,
         "non_subscriptions": {
             "com.cinnamonmobile.StocksLiveFree.NoAdds": [{
                 "id": "40295cc08a",
                 "is_sandbox": false,
                 "original_purchase_date": "2019-03-22T17:52:04Z",
                 "purchase_date": "2019-03-22T17:52:04Z",
                 "store": "app_store"
             }],
             "com.cinnamonmobile.StocksLiveFree.Portfolio": [{
                 "id": "c8c5167b0b",
                 "is_sandbox": false,
                 "original_purchase_date": "2019-03-22T17:06:28Z",
                 "purchase_date": "2019-03-22T17:06:28Z",
                 "store": "app_store"
             }],
             "com.cinnamonmobile.StocksLiveFree.RealTimeNASDAQ_NYSE": [{
                 "id": "c159abe7ce",
                 "is_sandbox": false,
                 "original_purchase_date": "2019-03-25T08:04:18Z",
                 "purchase_date": "2019-03-25T08:04:18Z",
                 "store": "app_store"
             }],
             "com.cinnamonmobile.StocksLiveFree.UpcomingDividend": [{
                 "id": "ded47a1bcf",
                 "is_sandbox": false,
                 "original_purchase_date": "2019-06-19T07:30:59Z",
                 "purchase_date": "2019-06-19T07:30:59Z",
                 "store": "app_store"
             }]
         },
         "original_app_user_id": "F6862686180809447439",
         "original_application_version": "4.5",
         "original_purchase_date": "2017-02-08T16:25:58Z",
         "other_purchases": {
             "com.cinnamonmobile.StocksLiveFree.NoAdds": {
                 "purchase_date": "2019-03-22T17:52:04Z"
             },
             "com.cinnamonmobile.StocksLiveFree.Portfolio": {
                 "purchase_date": "2019-03-22T17:06:28Z"
             },
             "com.cinnamonmobile.StocksLiveFree.RealTimeNASDAQ_NYSE": {
                 "purchase_date": "2019-03-25T08:04:18Z"
             },
             "com.cinnamonmobile.StocksLiveFree.UpcomingDividend": {
                 "purchase_date": "2019-06-19T07:30:59Z"
             }
         },
         "subscriptions": {
             "rc_promo_com.cinnamonmobile.StocksLiveFree.699_1m_1w0_monthly": {
                 "billing_issues_detected_at": null,
                 "expires_date": "2021-05-23T19:13:46Z",
                 "grace_period_expires_date": null,
                 "is_sandbox": false,
                 "original_purchase_date": "2021-04-22T19:13:46Z",
                 "period_type": "normal",
                 "purchase_date": "2021-04-22T19:13:46Z",
                 "store": "promotional",
                 "unsubscribe_detected_at": null
             }
         }
     }
 }
"""



}
