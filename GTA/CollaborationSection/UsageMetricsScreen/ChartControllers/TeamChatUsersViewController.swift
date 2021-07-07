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
    
    var dataProvider: UsageMetricsDataProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateChartData()
    }

    func updateChartData() {
        guard let activeUsersData = dataProvider?.teamsChatUserData.sorted(by: {$0.percent ?? 0 < $1.percent ?? 0}), !activeUsersData.isEmpty else { return }
        let chartValues = activeUsersData.enumerated().map { (index, dataEntry) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(index), y: dataEntry.percent ?? 0)
        }

        setChartView()
        setXAxis(activeUsersData)
        setLeftAxis(activeUsersData)
        setRightAxix()


        let dataSet = BarChartDataSet(entries: chartValues, label: nil)
        dataSet.setColor(UIColor(hex: 0x428DF7))
        dataSet.valueFont = .systemFont(ofSize: 14)
        
        let data = BarChartData(dataSets: [dataSet])
        data.setDrawValues(true)
        data.barWidth = 0.59
        data.setValueFormatter(DefaultValueFormatter(formatter: procentFormatter()))
        chartView.data = data
        
        let gridView = gridView()
        chartView.addSubview(gridView)
        gridView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 60),
            gridView.trailingAnchor.constraint(equalTo: chartView.trailingAnchor, constant: -32),
            gridView.topAnchor.constraint(equalTo: chartView.topAnchor, constant: 8),
            gridView.bottomAnchor.constraint(equalTo: chartView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setXAxis(_ userData: [TeamsChatUserDataEntry]) {
        let countries = userData.map{data -> String in
            return data.countryCode ?? ""
        }
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.labelCount = countries.count
        xAxis.valueFormatter = IndexAxisValueFormatter(values: countries)
        xAxis.labelFont = .systemFont(ofSize: 14)
        xAxis.labelTextColor = .lightGray
    }
    
    private func setLeftAxis(_ userData: [TeamsChatUserDataEntry]) {
        let leftAxis = chartView.leftAxis
        let maxValueBarMultiplier: Double = 1.4
        let maxValue = userData.max(by: {$0.percent ?? 0 < $1.percent ?? 0})?.percent ?? 0
        leftAxis.axisMaximum = maxValueBarMultiplier * maxValue
        leftAxis.enabled = false
        leftAxis.drawGridLinesEnabled = false
    }
    
    private func setRightAxix() {
        let righAxis = chartView.rightAxis
        righAxis.enabled = false
        righAxis.drawGridLinesEnabled = false
    }
    
    private func setChartView() {
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
    }
    
    private func gridView() -> UIView {
        let gv = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        gv.borderWidth = 1
        gv.borderColor = .lightGray
        gv.backgroundColor = .clear
        
        return gv
    }
}

extension TeamChatUsersViewController {
    func procentFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.multiplier = 1.0
        formatter.percentSymbol = "%"
        
        return formatter
    }
}
