//
//  Constants.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 22.04.2021.
//

import Foundation

class Constants {
    static let ticketSupportEmail = "service.desk@2knzn4q0e9o8tlx4di2oeimin1goubnbotpk3fcky2mdc99t5w.7b-4cgzeaa.cs190.case.sandbox.salesforce.com"
    static let sortingKey = "storedSortingType"
    static let filterKey = "storedFilterType"
    // MARK: Push notifications constants
    static let payloadKey = "payload"
    static let pushTypeKey = "push_type"
    static let pushTypeEmergencyOutage = "Emergency Outage"
    static let pushTypeProductionAlert = "Production Alert"
}

class NotificationsNames {
    static let emergencyOutageNotificationReceived = "emergencyOutageNotificationReceived"
    static let productionAlertNotificationReceived = "productionAlertNotificationReceived"
    static let globalAlertWillShow = "globalAlertWillShow"
}
