//
//  ProductionAlertsResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 22.06.2021.
//

import Foundation

struct ProductionAlertsResponse {//}: Codable {
    var meta: ResponseMetaData?
    var data: [ProductionAlertsRow?]?
}

struct ProductionAlertsRow {//}: Codable {
    var id: String?
    var title: String?
    var date: String?
    var status: String?
    var alertStatus: TicketStatus? {
        switch status?.lowercased() {
        case "new":
            return .new
        case "closed":
            return .closed
        case "open":
            return .open
        default:
            return TicketStatus.none
        }
    }
    var start: String?
    var duration: String?
    var summary: String?
    var isRead: Bool = false
}
