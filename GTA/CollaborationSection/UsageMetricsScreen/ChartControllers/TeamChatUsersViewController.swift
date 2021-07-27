//
//  TeamChatUsersViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.07.2021.
//

import Foundation
import UIKit
import Charts

class TeamChatUsersViewController: UIViewController {

    @IBOutlet weak var chartView: HorizontalBarChartView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var chartData: [String : [TeamsChatUserDataEntry]]?
    var key: String {
        return chartData?.keys.first ?? ""
    }
    var gridView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateChartData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleLabel.text = key
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addGridView()
    }
    
    func updateChartData() {
        guard let activeUsersData = chartData?[key]?.sorted(by: {$0.percent ?? 0 < $1.percent ?? 0}), !activeUsersData.isEmpty else { return }
        let chartValues = activeUsersData.enumerated().map { (index, dataEntry) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(index), y: dataEntry.percent ?? 0)
        }
        
        setChartView(activeUsersData)
        setData(chartValues)
    }
    
    func addGridView() {
        guard let linesCount = chartData?[key]?.count, linesCount > 1 else {return}
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

extension TeamChatUsersViewController {
    func procentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.multiplier = 1.0
        formatter.percentSymbol = "%"
        
        return formatter
    }
}
// Grid functions
extension TeamChatUsersViewController {
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

extension TeamChatUsersViewController: ChartDimensions {
    var optimalHeight: CGFloat {
        let linesCount = chartData?[key]?.count ?? 0
        return 120 + CGFloat(linesCount) * ChartsFormatting.horizontalBarOptimalHeight
    }
}
