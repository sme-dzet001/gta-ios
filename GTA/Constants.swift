//
//  Constants.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 22.04.2021.
//

import Foundation
import UIKit

class Constants {
    static var ticketSupportEmail: String {
        #if GTA
        return "gta-app@k-1mklc87f853pykhy82hbwh6tmdr4h9faxa2b74x99if8tw3s3z.7-jlcaeao.na117.case.salesforce.com"
        #else
        return "gta-app@p-uwi73v2uj5on3cc4mbzmdizt0mgw04qxttkzz0m2cc4vec0yp.7h-9przeaq.cs201.case.sandbox.salesforce.com"
        #endif
    }
    static let sortingKey = "storedSortingType"
    static let filterKey = "storedFilterType"
    // MARK: Push notifications constants
    static let payloadKey = "payload"
    static let pushTypeKey = "push_type"
    static let pushTypeEmergencyOutage = "Emergency Outage"
    static let pushTypeProductionAlert = "Production Alert"
    static let pushTypeGlobalProductionAlert = "Global Production Alert"
    static let isNeedLogOut = "isNeedLogOut"
}

class NotificationsNames {
    static let emergencyOutageNotificationReceived = "emergencyOutageNotificationReceived"
    static let productionAlertNotificationReceived = "productionAlertNotificationReceived"
    static let globalProductionAlertNotificationReceived = "globalProductionAlertNotificationReceived"
    static let globalAlertWillShow = "globalAlertWillShow"
    static let emergencyOutageNotificationDisplayed = "emergencyOutageNotificationDisplayed"
    static let productionAlertNotificationDisplayed = "productionAlertNotificationDisplayed"
    static let globalProductionAlertNotificationDisplayed = "globalProductionAlertNotificationDisplayed"
    static let updateActiveProductionAlertStatus = "updateActiveProductionAlertStatus"
    static let loggedOut = "loggedOut"
}

class ChartsFormatting {
    static let gridColor = UIColor(hex: 0xE5E5EA)
    static let labelTextColor = UIColor(hex: 0xAEAEB2)
    static let gridLineWidth: CGFloat = 1
    static let labelFont = UIFont(name: "SFProText-Regular", size: 10)
    static let horizontalBarOptimalHeight: CGFloat = 24
}

class DefaultImageNames {
    static let whatsNewPlaceholder = "whatsNewPlaceholder"
}
