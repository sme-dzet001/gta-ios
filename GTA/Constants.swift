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
    static let pushType = "Emergency Outage"
}

class NotificationsNames {
    static let emergencyOutageNotificationReceived = "emergencyOutageNotificationReceived"
    static let globalAlertWillShow = "globalAlertWillShow"
}

class ChartsFormatting {
    static let gridColor = UIColor(hex: 0xE5E5EA)
    static let labelTextColor = UIColor(hex: 0xAEAEB2)
    static let gridLineWidth: CGFloat = 1
    static let labelFont = UIFont(name: "SFProText-Regular", size: 10)
}
