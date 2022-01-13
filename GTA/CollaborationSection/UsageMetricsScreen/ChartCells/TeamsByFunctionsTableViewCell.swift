//
//  TeamsByFunctionsTableViewCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 06.10.2021.
//

import UIKit
import Charts

protocol ScrollableChartCellDelegate: AnyObject {
    func scrollableChartCellDidScrolled(_ cell: UITableViewCell, with contentOffset: CGPoint)
}

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


class ChartDataSourceSelectionButton: UIButton {
    var selectedBgView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        addSubview(selectedBgView)
        selectedBgView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectedBgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            selectedBgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            selectedBgView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            selectedBgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
        ])
        selectedBgView.backgroundColor = .white
        selectedBgView.cornerRadius = 8
        selectedBgView.isHidden = true
    }
    
    var isActive: Bool = false {
        didSet {
            selectedBgView.isHidden = !isActive
        }
    }
}


class TeamsByFunctionsTableViewCell: UITableViewCell {
    
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
    
    @IBOutlet var selectorBtns: [ChartDataSourceSelectionButton]!
    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: ScrollableChartCellDelegate?
    
    let chartViewGridWidth: CGFloat = 64
    let lineColor = UIColor(hex: 0x428DF7)
    let chartLineWidth: CGFloat = 2
    let chartLineCircleRadius: CGFloat = 8
    
    var chartsData: TeamsByFunctionsLineChartData? 
    var dataSourceIdx: Int = 0 {
        didSet {
            updateLabels()
            updateChartData()
            updateSelectorBtns()
            defaultScrollPosition()
        }
    }

    var lineChartData: [(period: String?, value: Int?)] {
        let count = chartsData?.data?.count ?? 0
        guard count > dataSourceIdx else { return [(period: String?, value: Int?)]() }
        let values = chartsData?.data?[dataSourceIdx] ?? []
        return values.map({ return (period: $0.formattedLegend, value: $0.value) })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        chartScrollView.delegate = self
    }
    
    
    func updateData() {
        DispatchQueue.main.async { [weak self] in
            self?.configureChart()
            self?.titleLabel.text = self?.chartsData?.title
        }
    }
    
    @IBAction func dataSourceSelectorBtnTapped(_ sender: ChartDataSourceSelectionButton) {
        dataSourceIdx = sender.tag - 500
        chartScrollView.stopDecelerating()
    }
    
    func updateSelectorBtns() {
        for (index, selectorBtn) in selectorBtns.enumerated() {
            selectorBtn.isActive = (selectorBtn.tag - 500) == dataSourceIdx
            if (chartsData?.data?.count ?? 0) > index {
                let buttonTitle = (chartsData?.data?[index] ?? []).compactMap({$0.chartSubtitle}).first
                selectorBtn.setTitle(buttonTitle, for: .normal)
                selectorBtn.isHidden = false
            } else {
                selectorBtn.isHidden = true
            }
        }
    }
    
    func configureChart() {
        setupChartView()
        updateLabels()
        updateChartData()
        updateSelectorBtns()
    }
    
    func updateBlurViews() {
        blurViewLeft.isHidden = !(chartScrollView.contentOffset.x > 0)
        blurViewRight.isHidden = !(ceil(Double(chartScrollView.contentOffset.x)) < floor(Double(chartViewWidth.constant - chartScrollView.bounds.size.width)))
    }
    
    func defaultScrollPosition() {
        layoutIfNeeded()
        chartScrollView.contentOffset = CGPoint(x: chartViewWidth.constant - chartScrollView.bounds.size.width, y: 0)
    }
    
    func setScrollPosition(to point: CGPoint?) {
        if let point = point {
            chartScrollView.contentOffset = point
        } else {
            defaultScrollPosition()
        }
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
        if previousToLastValue != 0 {
            percentLabel.text = String(format: "%.1f", locale: Locale.current, Double(100) * lastValue / previousToLastValue).replacingOccurrences(of: ".0", with: "") + "%"
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
        chartScrollViewTrailing.constant = extraSizeRight.width
        chartView.extraRightOffset = extraSizeRight.width / 2
        
        let extraSizeLeft = (firstLabel as NSString).size(withAttributes: [.font : ChartsFormatting.labelFont as Any])
        chartScrollViewLeading.constant = CGFloat(10) - extraSizeLeft.width / 2
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
    
}

extension TeamsByFunctionsTableViewCell: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateBlurViews()
        delegate?.scrollableChartCellDidScrolled(self, with: scrollView.contentOffset)
    }
}

extension TeamsByFunctionsTableViewCell: ChartDimensions {
    var optimalHeight: CGFloat {
        return 370
    }
}

