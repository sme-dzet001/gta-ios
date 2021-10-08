//
//  TeamChatUsersCell.swift
//  GTA
//
//  Created by Артем Хрещенюк on 06.10.2021.
//

import UIKit
import Charts

class TeamChatUsersCell: UITableViewCell {

    @IBOutlet weak var chartView: HorizontalBarChartView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var chartData: TeamsChatUserData? {
        didSet {
            updateChartData()
        }
    }
    var gridView = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateChartData()
    }
    
    func updateChartData() {
        titleLabel.text = chartData?.title
        guard let activeUsersData = chartData?.data?.sorted(by: {$0.percent ?? 0 < $1.percent ?? 0}), !activeUsersData.isEmpty else { return }
        let chartValues = activeUsersData.enumerated().map { (index, dataEntry) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(index), y: dataEntry.percent ?? 0)
        }
        
        setChartView(activeUsersData)
        setData(chartValues)
    }
    
    func addGridView() {
        guard let linesCount = chartData?.data?.count, linesCount > 1 else {return}
        gridView = setGridView()
        chartView.addSubview(gridView)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: chartView.xAxis.labelWidth + chartView.minOffset),
            gridView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -40),
            gridView.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 10),
            gridView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: -10)
        ])
        gridView.layoutIfNeeded()
        setHorizontalLines(linesCount: linesCount - 1, lineHeight: ChartsFormatting.gridLineWidth)
    }
    
    private func setData(_ values: [BarChartDataEntry]) {
        let dataSet = BarChartDataSet(entries: values, label: nil)
        dataSet.setColor(UIColor(hex: 0x428DF7))
        dataSet.valueFont = ChartsFormatting.labelFont ?? .systemFont(ofSize: 10)
        
        let data = BarChartData(dataSets: [dataSet])
        data.setDrawValues(true)
        data.barWidth = 0.67
        data.setValueFormatter(DefaultValueFormatter(formatter: procentFormatter()))
        chartView.data = data
    }
    
    private func setChartView(_ activeUsers: [TeamsChatUserDataEntry]) {
        // Chart
        chartView.isUserInteractionEnabled = false
        chartView.chartDescription?.enabled = false
        chartView.chartDescription?.text = nil
        chartView.drawBarShadowEnabled = false
        chartView.drawBordersEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.legend.enabled = false
        chartView.leftAxis.enabled = false
        chartView.rightAxis.enabled = false
        chartView.drawValueAboveBarEnabled = true
        chartView.maxVisibleCount = 60
        
        // XAxis
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.labelCount = activeUsers.count
        xAxis.valueFormatter = IndexAxisValueFormatter(values: activeUsers.map{data -> String in return data.countryCode ?? ""
        })
        xAxis.labelFont = ChartsFormatting.labelFont ?? .systemFont(ofSize: 10)
        xAxis.labelTextColor = ChartsFormatting.labelTextColor
        
        // LeftAxis
        let leftAxis = chartView.leftAxis
        let maxValueBarMultiplier: Double = 1.4
        let maxValue = activeUsers.max(by: {$0.percent ?? 0 < $1.percent ?? 0})?.percent ?? 0
        leftAxis.axisMaximum = maxValueBarMultiplier * maxValue
        leftAxis.enabled = false
        leftAxis.drawGridLinesEnabled = false
        
        // RightAxis
        let righAxis = chartView.rightAxis
        righAxis.enabled = false
        righAxis.drawGridLinesEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.pinchZoomEnabled = false
    }
}

extension TeamChatUsersCell {
    func procentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.decimalSeparator = "."
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.multiplier = 1.0
        formatter.percentSymbol = "%"
        
        return formatter
    }
}
// Grid functions
extension TeamChatUsersCell {
    
    private func setGridView() -> UIView {
        let gv = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        gv.borderWidth = ChartsFormatting.gridLineWidth
        gv.borderColor = ChartsFormatting.gridColor
        gv.backgroundColor = .clear
        
        return gv
    }
    
    private func setHorizontalLines(linesCount: Int, lineHeight: CGFloat = 1) {
        guard linesCount > 1 else { return }
        let containerHeight = gridView.frame.height
        let containerWidth = gridView.frame.width
        let linesSpacing = (containerHeight - CGFloat(linesCount + 1) * lineHeight) / (CGFloat(linesCount) + 1)
        
        for i in 1..<linesCount + 1 {
            let lineView = UIView(frame: CGRect(x: 0, y: (linesSpacing + lineHeight) * CGFloat(i), width: containerWidth, height: lineHeight))
            lineView.backgroundColor = ChartsFormatting.gridColor
            gridView.addSubview(lineView)
        }
    }
 
}

extension TeamChatUsersCell: ChartDimensions {
    var optimalHeight: CGFloat {
        let linesCount = chartData?.data?.count ?? 0
        return 170 + CGFloat(linesCount) * ChartsFormatting.horizontalBarOptimalHeight
    }
}

extension TeamChatUsersCell: HorizontallBarChartDataChangedDelegate {
    func verticalBarChartDataChanged(newData: TeamsChatUserData?) {
        chartData = newData
        updateChartData()
    }
}