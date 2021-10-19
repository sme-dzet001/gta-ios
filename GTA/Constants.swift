//
//  Constants.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 22.04.2021.
//

import Foundation
import UIKit

class Constants {
    static let ticketSupportEmail = "service.desk@2knzn4q0e9o8tlx4di2oeimin1goubnbotpk3fcky2mdc99t5w.7b-4cgzeaa.cs190.case.sandbox.salesforce.com"
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
