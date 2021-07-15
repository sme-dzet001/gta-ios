//
//  ActiveUsersViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 14.07.2021.
//

import UIKit
import Charts

class ActiveUsersViewController: LineChartViewController {
    override var lineChartData: [(period: String?, value: Int?)] {
        return dataProvider?.activeUsersData.map({ return (period: $0.period, value: $0.value) }) ?? []
    }
}

extension ActiveUsersViewController: ChartDimensions {
    var optimalHeight: CGFloat {
        return 294
    }
}
