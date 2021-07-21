import Foundation

// swiftlint:disable identifier_name
enum AttributionKey: String {
    case idfa = "rc_idfa",
         idfv = "rc_idfv",
         ip = "rc_ip_address",
         gpsAdId = "rc_gps_adid",
         networkID = "rc_attribution_network_id"

    enum Adjust: String {
        case id = "adid",
             network = "network",
             campaign = "campaign",
             adGroup = "adgroup",
             creative = "creative"
    }

    enum AppsFlyer: String {
        case id = "rc_appsflyer_id",
             campaign = "campaign",
             channel = "af_channel",
             mediaSource = "media_source",
             adSet = "adset",
             ad = "af_ad",
             adGroup = "adgroup",
             adKeywords = "af_keywords",
             adId = "ad_id",
             dataKey = "data",
             statusKey = "status"
    }

    enum Branch: String {
        case campaign,
             channel
    }

    enum MParticle: String {
        case id = "mpid"
    }
}
