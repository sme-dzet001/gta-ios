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
        var data = [(period: String?, value: Int?)]()
        let values = chartData?.values ?? []
        let legends = chartData?.legends ?? []
        for (index, value) in values.enumerated() where index < legends.count {
            let legend = legends[index].getDateForUsageMetrics()
            data.append((period: legend, value: Int(value)))
        }
        return data
    }
    
    var chartData: ChartStructure?
}

extension ActiveUsersViewController: ChartDimensions {
    var optimalHeight: CGFloat {
        return 294
    }
}
