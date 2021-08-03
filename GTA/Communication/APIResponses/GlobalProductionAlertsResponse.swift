//
//  GlobalProductionAlertsResponse.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.08.2021.
//

import Foundation

struct GlobalProductionAlertsResponse: Codable {
    var meta: ResponseMetaData?
    var data: GlobalProductionAlertsRows?
}

struct GlobalProductionAlertsRows: Codable {
    var rows: [ProductionAlertsRow?]?
}
