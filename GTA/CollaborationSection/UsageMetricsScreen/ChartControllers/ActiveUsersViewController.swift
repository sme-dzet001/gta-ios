//
//  ActiveUsersViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 03.07.2021.
//

import UIKit
import Charts

class ChartScrollView : UIScrollView, UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class ActiveUsersYValueFormatter: NSObject, IAxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String(format: "%.1fk", locale: Locale.current, value / 1000).replacingOccurrences(of: ".0", with: "")
    }
}

class ActiveUsersXValueFormatter: NSObject, IAxisValueFormatter {
    var xLabels: [String] = []
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard index < xLabels.count else { return "" }
        return xLabels[index]
    }
}

class ActiveUsersViewController: UIViewController {
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var chartViewWidth: NSLayoutConstraint!
    
    let chartViewGridWidth: CGFloat = 64
    let lineColor = UIColor(hex: 0x428DF7)
    let chartLineWidth: CGFloat = 2
    let chartLineCircleRadius: CGFloat = 8
    
    var dataProvider: UsageMetricsDataProvider?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateChartData()
    }
    
    func updateChartData() {
        guard let activeUsersData = dataProvider?.activeUsersData, !activeUsersData.isEmpty else { return }
        
        chartViewWidth.constant = CGFloat(chartViewGridWidth) * CGFloat(activeUsersData.count)
        
        let chartValues = activeUsersData.enumerated().map { (index, dataEntry) -> ChartDataEntry in
            return ChartDataEntry(x: Double(index), y: Double(dataEntry.value ?? 0))
        }
        
        let chartDataSet = LineChartDataSet(entries: chartValues)
        
        chartDataSet.drawValuesEnabled = false
        chartDataSet.setColor(lineColor)
        chartDataSet.setCircleColor(lineColor)
        chartDataSet.lineWidth = chartLineWidth
        chartDataSet.circleRadius = chartLineCircleRadius
        chartDataSet.drawCircleHoleEnabled = false
        chartDataSet.highlightEnabled = false
        
        let chartData = LineChartData(dataSet: chartDataSet)

        chartView.data = chartData
        
        //Common chart formatting
        
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        
        setLabelsFont(labelFont: ChartsFormatting.labelFont)
        setLabelsTextColor(labelsTextColor: ChartsFormatting.labelTextColor)
        setGridColor(gridColor: ChartsFormatting.gridColor)
        setGridLineWidth(gridLineWidth: ChartsFormatting.gridLineWidth)
        
        //Horizontal axis formatting
        
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.labelPosition = .bottom
        let xValueFormatter = ActiveUsersXValueFormatter()
        xValueFormatter.xLabels = activeUsersData.map( { ($0.period ?? "") } )
        chartView.xAxis.valueFormatter = xValueFormatter
        chartView.xAxis.setLabelCount(xValueFormatter.xLabels.count, force: true)
        
        //Vertical axis formatting
        
        chartView.leftAxis.drawAxisLineEnabled = false
        //chartView.leftAxis.drawLabelsEnabled = false
        chartView.leftAxis.valueFormatter = ActiveUsersYValueFormatter()
        
        let minYValue = chartView.leftAxis.axisMinimum
        
        var minYFactor = Int(minYValue) / 1000
        if Double(minYFactor) * 1000 > minYValue {
            minYFactor -= 1
        }
        
        chartView.leftAxis.axisMinimum = Double(minYFactor) * 1000
        
        let maxYValue = chartView.leftAxis.axisMaximum
        
        var maxYFactor = Int(maxYValue) / 1000
        if Double(maxYFactor) * 1000 < maxYValue {
            maxYFactor += 1
        }
        
        chartView.leftAxis.axisMaximum = Double(maxYFactor) * 1000
        
        chartView.leftAxis.setLabelCount(maxYFactor - minYFactor + 1, force: true)
        
        chartView.leftAxis.spaceTop = 0
        chartView.leftAxis.spaceBottom = 0
    }

    func setLabelsFont(labelFont: UIFont?) {
        guard let labelFont = labelFont else { return }
        chartView.xAxis.labelFont = labelFont
        chartView.leftAxis.labelFont = labelFont
    }
    
    func setLabelsTextColor(labelsTextColor: UIColor) {
        chartView.xAxis.labelTextColor = labelsTextColor
        chartView.leftAxis.labelTextColor = labelsTextColor
    }
    
    func setGridColor(gridColor: UIColor) {
        chartView.xAxis.gridColor = gridColor
        chartView.leftAxis.gridColor = gridColor
    }
    
    func setGridLineWidth(gridLineWidth: CGFloat) {
        chartView.xAxis.gridLineWidth = gridLineWidth
        chartView.leftAxis.gridLineWidth = gridLineWidth
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
