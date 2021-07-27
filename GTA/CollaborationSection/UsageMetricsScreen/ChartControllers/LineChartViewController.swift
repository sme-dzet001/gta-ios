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

class LineChartXValueFormatter: NSObject, IAxisValueFormatter {
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
    
    @IBOutlet weak var blurViewLeft: UIView!
    @IBOutlet weak var blurViewRight: UIView!
    
    @IBOutlet weak var chartViewWidth: NSLayoutConstraint!
    @IBOutlet weak var chartScrollView: UIScrollView!
    @IBOutlet weak var chartScrollViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var chartScrollViewLeading: NSLayoutConstraint!
    @IBOutlet weak var verticalAxisViewTop: NSLayoutConstraint!
    @IBOutlet weak var verticalAxisViewBottom: NSLayoutConstraint!
    
    let chartViewGridWidth: CGFloat = 64
    let lineColor = UIColor(hex: 0x428DF7)
    let chartLineWidth: CGFloat = 2
    let chartLineCircleRadius: CGFloat = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupChartView()
        updateLabels()
        updateChartData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollView()
    }
    
    var lineChartData: [(period: String?, value: Int?)] {
        return []
    }
    
    func updateBlurViews() {
        blurViewLeft.isHidden = !(chartScrollView.contentOffset.x > 0)
        blurViewRight.isHidden = !(chartScrollView.contentOffset.x < (chartViewWidth.constant - (UIScreen.main.bounds.width - chartScrollViewLeading.constant + chartScrollViewTrailing.constant)))
    }
    
    func updateScrollView() {
        chartScrollView.contentOffset = CGPoint(x: chartViewWidth.constant - (UIScreen.main.bounds.width - chartScrollViewLeading.constant + chartScrollViewTrailing.constant), y: 0)
    }
    
    func updateLabels() {
        guard lineChartData.count > 1 else {
            maxValueLabel.text = ""
            percentLabel.text = ""
            return
        }
        let lastValue = Double(lineChartData.map({ return $0.value ?? 0 }).last ?? 0)
        let maxValueNumberFormatter = NumberFormatter()
        maxValueNumberFormatter.numberStyle = .decimal
        maxValueNumberFormatter.decimalSeparator = "."
        maxValueLabel.text = String.convertBigValueToString(value: lastValue)
        let previousToLastValue = Double(lineChartData.map({ return $0.value ?? 0 })[lineChartData.count - 2])
        if lastValue != 0 {
            percentLabel.text = String(format: "%.1f", locale: Locale.current, Double(100) * previousToLastValue / lastValue).replacingOccurrences(of: ".0", with: "") + "%"
        }
    }
    
    var xValueFormatter: LineChartXValueFormatter {
        let xValueFormatter = LineChartXValueFormatter()
        xValueFormatter.xLabels = lineChartData.map( { ($0.period ?? "") } )
        return xValueFormatter
    }
    
    func setupChartView() {
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
        chartView.xAxis.valueFormatter = xValueFormatter
        
        //Vertical axis formatting
        
        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.leftAxis.drawLabelsEnabled = false
        
        chartView.rightAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        
        chartView.leftAxis.spaceTop = 0
        chartView.leftAxis.spaceBottom = 0
    }
    
    func updateChartData() {
        guard !lineChartData.isEmpty else { return }
        
        chartView.clearValues()
        chartView.leftAxis.resetCustomAxisMin()
        chartView.leftAxis.resetCustomAxisMax()
        
        chartViewWidth.constant = CGFloat(chartViewGridWidth) * CGFloat(lineChartData.count)
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.pinchZoomEnabled = false
        
        
        let chartValues = lineChartData.enumerated().map { (index, dataEntry) -> ChartDataEntry in
            return ChartDataEntry(x: Double(index), y: Double(dataEntry.value ?? 0))
        }
        
        let chartDataSet = LineChartDataSet(entries: chartValues)
        chartDataSet.mode = .horizontalBezier
        chartDataSet.drawValuesEnabled = false
        chartDataSet.setColor(lineColor)
        chartDataSet.setCircleColor(lineColor)
        chartDataSet.lineWidth = chartLineWidth
        chartDataSet.circleRadius = chartLineCircleRadius
        chartDataSet.drawCircleHoleEnabled = false
        chartDataSet.highlightEnabled = false
        
        let chartData = LineChartData(dataSet: chartDataSet)

        chartView.data = chartData
        
        //Horizontal axis formatting
        
        chartView.xAxis.setLabelCount(lineChartData.count, force: true)
                
        //Vertical axis formatting
        
        let minYValue = lineChartData.map({ return Double($0.value ?? 0) }).min() ?? 0
        chartView.leftAxis.axisMinimum = minYValue.getAxisMinimum()
        
        let lineChartValues = lineChartData.map({ return Double($0.value ?? 0) })
        chartView.leftAxis.axisMaximum = lineChartValues.max()?.getAxisMaximum() ?? 0.0
        let verticalLabelsCount = 3
        chartView.leftAxis.setLabelCount(verticalLabelsCount, force: true)
        var labels: [String] = []
        for yAxisValue in [chartView.leftAxis.axisMinimum, (chartView.leftAxis.axisMaximum + chartView.leftAxis.axisMinimum) / 2, chartView.leftAxis.axisMaximum] {
            labels.insert(String.convertBigValueToString(value: yAxisValue, for: true), at: 0)
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
        for leftAxisLabel in verticalAxisStackView.arrangedSubviews {
            verticalAxisStackView.removeArrangedSubview(leftAxisLabel)
            leftAxisLabel.removeFromSuperview()
        }
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
        chartScrollViewTrailing.constant = CGFloat(-40) + extraSizeRight.width / 2
        chartView.extraRightOffset = extraSizeRight.width / 2
        
        let extraSizeLeft = (firstLabel as NSString).size(withAttributes: [.font : ChartsFormatting.labelFont as Any])
        chartScrollViewLeading.constant = CGFloat(60) - extraSizeLeft.width / 2
        chartView.extraLeftOffset = extraSizeLeft.width / 2
        
        addBlurViewLeft()
        addBlurViewRight()
        
        updateBlurViews()
    }
    
    func addBlurViewLeft() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurViewLeft.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3).cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.startPoint = CGPoint(x: 1.0, y: 0.0)
        gradientMaskLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        blurViewLeft.layer.mask = gradientMaskLayer
    }
    
    func addBlurViewRight() {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurViewRight.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3).cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientMaskLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        blurViewRight.layer.mask = gradientMaskLayer
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

extension LineChartViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBlurViews()
    }
}
