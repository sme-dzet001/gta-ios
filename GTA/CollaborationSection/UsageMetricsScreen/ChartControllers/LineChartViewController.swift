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

class ActiveUsersXValueFormatter: NSObject, IAxisValueFormatter {
    var xLabels: [String] = []
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard index < xLabels.count else { return "" }
        return xLabels[index]
    }
}

class LineChartViewController: UIViewController {
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var verticalAxisStackView: UIStackView!
    
    @IBOutlet weak var maxValueLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    
    @IBOutlet weak var chartViewWidth: NSLayoutConstraint!
    @IBOutlet weak var chartScrollViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var chartScrollViewLeading: NSLayoutConstraint!
    @IBOutlet weak var verticalAxisViewTop: NSLayoutConstraint!
    @IBOutlet weak var verticalAxisViewBottom: NSLayoutConstraint!
    @IBOutlet weak var verticalAxisViewTrailing: NSLayoutConstraint!
    
    let chartViewGridWidth: CGFloat = 64
    let lineColor = UIColor(hex: 0x428DF7)
    let chartLineWidth: CGFloat = 2
    let chartLineCircleRadius: CGFloat = 8
    
    var dataProvider: UsageMetricsDataProvider?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateLabels()
        updateChartData()
    }
    
    var lineChartData: [(period: String?, value: Int?)] {
        return dataProvider?.activeUsersData.map({ return (period: $0.period, value: $0.value) }) ?? []
    }
    
    func updateLabels() {
        guard !lineChartData.isEmpty else { return }
        let maxValue = lineChartData.map({ return $0.value ?? 0 }).max() ?? 0
        let maxValueNumberFormatter = NumberFormatter()
        maxValueNumberFormatter.numberStyle = .decimal
        maxValueLabel.text = maxValueNumberFormatter.string(from: NSNumber(value: maxValue))?.replacingOccurrences(of: ",", with: " ")
    }
    
    func updateChartData() {
        guard !lineChartData.isEmpty else { return }
        
        chartViewWidth.constant = CGFloat(chartViewGridWidth) * CGFloat(lineChartData.count)
        
        let chartValues = lineChartData.enumerated().map { (index, dataEntry) -> ChartDataEntry in
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
        xValueFormatter.xLabels = lineChartData.map( { ($0.period ?? "") } )
        chartView.xAxis.valueFormatter = xValueFormatter
        chartView.xAxis.setLabelCount(xValueFormatter.xLabels.count, force: true)
        
        //chartView.setVisibleXRangeMaximum(Double(view.frame.size.width / chartViewGridWidth))
        
        //Vertical axis formatting
        
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.leftAxis.drawLabelsEnabled = false
        
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
        
        chartView.leftAxis.spaceTop = 0
        chartView.leftAxis.spaceBottom = 0
        
        let verticalLabelsCount = maxYFactor - minYFactor + 1
        chartView.leftAxis.setLabelCount(verticalLabelsCount, force: true)
        
        var labels: [String] = []
        for i in (minYFactor..<(maxYFactor + 1)) {
            labels.insert(String(format: "%.1fk", locale: Locale.current, Double(i)).replacingOccurrences(of: ".0", with: ""), at: 0)
        }
        
        setupLeftAxisCustomView(labels: labels, labelsFont: ChartsFormatting.labelFont, labelsTextColor: ChartsFormatting.labelTextColor)
        
        setUpBlurViews(firstLabel: lineChartData.first?.period ?? "", lastLabel: lineChartData.last?.period ?? "")
    }
    
    func setupLeftAxisCustomView(labels: [String], labelsFont: UIFont?, labelsTextColor: UIColor) {
        guard labels.count > 1 else { return }
        guard let labelsFont = labelsFont else { return }
        let extraOffsetVertical = labelsFont.lineHeight / 2.5 + chartView.leftAxis.yOffset
        verticalAxisViewTop.constant = extraOffsetVertical
        verticalAxisViewBottom.constant = -chartView.xAxis.labelHeight
        for i in (0..<labels.count) {
            let label = labels[i]
            let leftAxisLabel = UILabel()
            leftAxisLabel.text = label
            leftAxisLabel.font = labelsFont
            leftAxisLabel.textColor = labelsTextColor
            leftAxisLabel.textAlignment = .right
            verticalAxisStackView.addArrangedSubview(leftAxisLabel)
        }
    }
    
    func setUpBlurViews(firstLabel: String, lastLabel: String) {
        let extraSizeRight = (lastLabel as NSString).size(withAttributes: [.font : ChartsFormatting.labelFont as Any])
        chartScrollViewTrailing.constant += extraSizeRight.width / 2
        chartView.extraRightOffset = extraSizeRight.width / 2
        
        let extraSizeLeft = (firstLabel as NSString).size(withAttributes: [.font : ChartsFormatting.labelFont as Any])
        chartScrollViewLeading.constant -= extraSizeLeft.width / 2
        chartView.extraLeftOffset = extraSizeLeft.width / 2
        
        verticalAxisViewTrailing.constant += extraSizeLeft.width / 2
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

extension LineChartViewController: ChartDimensions {
    var optimalHeight: CGFloat {
        return 294
    }
}
