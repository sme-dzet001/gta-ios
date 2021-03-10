//
//  CollaborationResponses.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 10.03.2021.
//

import Foundation

struct CollaborationTipsAndTricksResponse: Codable {
    var meta: ResponseMetaData?
    var data: [String : TipsAndTricksData?]?
}

struct TipsAndTricksData: Codable {
    var data: QuickHelpData?
}
