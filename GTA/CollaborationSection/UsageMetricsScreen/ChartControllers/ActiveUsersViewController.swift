//
//  ActiveUsersViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 03.07.2021.
//

import UIKit
import Charts

class ActiveUsersViewController: UIViewController {
    
    @IBOutlet weak var chartView: LineChartView!
    
    var dataProvider: UsageMetricsDataProvider?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateChartData()
    }
    
    func updateChartData() {
        guard let activeUsersData = dataProvider?.activeUsersData, !activeUsersData.isEmpty else { return }
        let chartValues = activeUsersData.enumerated().map { (index, dataEntry) -> ChartDataEntry in
            return ChartDataEntry(x: Double(index), y: Double(dataEntry.value ?? 0))
        }
        
        let chartDataSet = LineChartDataSet(entries: chartValues)
        
        chartDataSet.drawValuesEnabled = false
        chartDataSet.setColor(UIColor(hex: 0x428DF7))
        chartDataSet.setCircleColor(UIColor(hex: 0x428DF7))
        chartDataSet.lineWidth = 2
        chartDataSet.circleRadius = 8
        chartDataSet.drawCircleHoleEnabled = false
        
        let chartData = LineChartData(dataSet: chartDataSet)

        chartView.data = chartData
        
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
