//
//  CustomerCenterConfigDataAPI.swift
//  SwiftAPITester
//
//  Created by Cesar de la Vega on 29/6/24.
//

import Foundation
import RevenueCat

func checkCustomerCenterConfigData(_ data: CustomerCenterConfigData) {
    let screens: [CustomerCenterConfigData.Screen.ScreenType: CustomerCenterConfigData.Screen] = data.screens
    let appearance: CustomerCenterConfigData.Appearance = data.appearance
    let localization: CustomerCenterConfigData.Localization = data.localization
    let support: CustomerCenterConfigData.Support = data.support
    let lastPublishedAppVersion = data.lastPublishedAppVersion
    let productId = data.productId

    let _: CustomerCenterConfigData = .init(screens: screens,
                                            appearance: appearance,
                                            localization: localization,
                                            support: support,
                                            lastPublishedAppVersion: lastPublishedAppVersion,
                                            productId: productId)
}

func checkHelpPath(_ path: CustomerCenterConfigData.HelpPath) {
    let id: String = path.id
    let title: String = path.title
    let url: URL? = path.url
    let openMethod: CustomerCenterConfigData.HelpPath.OpenMethod? = path.openMethod
    let type: CustomerCenterConfigData.HelpPath.PathType = path.type
    let detail: CustomerCenterConfigData.HelpPath.PathDetail? = path.detail

    let _: CustomerCenterConfigData.HelpPath = .init(id: id,
                                                     title: title,
                                                     url: url,
                                                     openMethod: openMethod,
                                                     type: type,
                                                     detail: detail)
}

func checkHelpPathDetail(_ detail: CustomerCenterConfigData.HelpPath.PathDetail) {
    switch detail {
    case .promotionalOffer(let offer):
        checkPromotionalOffer(offer)
    case .feedbackSurvey(let survey):
        checkFeedbackSurvey(survey)
    @unknown default:
        break
    }
}

func checkPromotionalOffer(_ offer: CustomerCenterConfigData.HelpPath.PromotionalOffer) {
    let iosOfferId: String = offer.iosOfferId
    let eligible: Bool = offer.eligible
    let title: String = offer.title
    let subtitle: String = offer.subtitle
    let productMapping: [String: String] = offer.productMapping

    let _: CustomerCenterConfigData.HelpPath.PromotionalOffer = .init(iosOfferId: iosOfferId,
                                                                      eligible: eligible,
                                                                      title: title,
                                                                      subtitle: subtitle,
                                                                      productMapping: productMapping)
}

func checkFeedbackSurvey(_ survey: CustomerCenterConfigData.HelpPath.FeedbackSurvey) {
    let title: String = survey.title
    let options: [CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option] = survey.options

    let _: CustomerCenterConfigData.HelpPath.FeedbackSurvey = .init(title: title, options: options)
}

func checkFeedbackSurveyOption(_ option: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option) {
    let id: String = option.id
    let title: String = option.title
    let promotionalOffer: CustomerCenterConfigData.HelpPath.PromotionalOffer? = option.promotionalOffer

    let _: CustomerCenterConfigData.HelpPath.FeedbackSurvey.Option = .init(id: id,
                                                                           title: title,
                                                                           promotionalOffer: promotionalOffer)
}

func checkScreen(_ screen: CustomerCenterConfigData.Screen) {
    let type: CustomerCenterConfigData.Screen.ScreenType = screen.type
    let title: String = screen.title
    let subtitle: String? = screen.subtitle
    let paths: [CustomerCenterConfigData.HelpPath] = screen.paths

    let _: CustomerCenterConfigData.Screen = .init(type: type, title: title, subtitle: subtitle, paths: paths)
}

func checkScreenType(_ type: CustomerCenterConfigData.Screen.ScreenType) {
    switch type {
    case .management, .noActive, .unknown:
        print(type.rawValue)
    @unknown default:
        break
    }
}

func checkPathType(_ type: CustomerCenterConfigData.HelpPath.PathType) {
    switch type {
    case .missingPurchase, .refundRequest, .changePlans, .cancel, .unknown:
        print(type.rawValue)
    @unknown default:
        break
    }
}
