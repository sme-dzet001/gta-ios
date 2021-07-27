//
//  BarChartCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.07.2021.
//

import UIKit
import Charts

class BarChartCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpBarChartView(with chartStructure: ChartStructure?) {
        guard let chartData = chartStructure else { return }
        titleLabel.text = chartData.title
        let width = calculateBarWidth(barCount: chartData.values.count)
        let yValues: [BarChartDataEntry] = getValues(with: chartData.values, width: width)
        guard !yValues.isEmpty else { return }
        let set = BarChartDataSet(entries: yValues, label: nil)
        set.drawIconsEnabled = true
        set.colors = getBarColors(for: yValues.count)
        let data = BarChartData(dataSet: set)
        data.highlightEnabled = false
        data.setDrawValues(false)
        data.barWidth = width
        let axisMaximum = Double(chartData.values.max() ?? 0.0).getAxisMaximum()
        setUpAxis(axisMaximum: axisMaximum)
        barChartView.scaleXEnabled = false
        barChartView.scaleYEnabled = false
        barChartView.pinchZoomEnabled = false
        barChartView.data = data
        barChartView.fitBars = true
        barChartView.extraBottomOffset = 13
        //barChartView.delegate = self
        let stackLabels = chartData.legends
        setUpChartLegend(for: yValues.count, labels: stackLabels)
    }
    
    private func setUpAxis(axisMaximum: Double) {
        let font = UIFont(name: "SFProText-Regular", size: 10) ?? barChartView.leftAxis.labelFont
        let axisColor = UIColor(hex: 0xE5E5EA)
        barChartView.leftAxis.labelFont = font
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.axisMaximum = axisMaximum
        barChartView.leftAxis.valueFormatter = BarChartLeftAxisValueFormatter()
        barChartView.rightAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.labelTextColor = UIColor(hex: 0xAEAEB2)
        barChartView.chartDescription?.enabled = false
        barChartView.xAxis.drawLabelsEnabled = false
        barChartView.rightAxis.drawLabelsEnabled = false
        barChartView.leftAxis.gridAntialiasEnabled = false
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.spaceBottom = 0
        barChartView.rightAxis.spaceBottom = 0
        barChartView.xAxis.axisLineColor = axisColor
        barChartView.rightAxis.axisLineColor = axisColor
        barChartView.leftAxis.axisLineColor = axisColor
        barChartView.leftAxis.gridColor = axisColor
        barChartView.rightAxis.gridColor = axisColor
        barChartView.xAxis.axisLineWidth = 1
        barChartView.rightAxis.axisLineWidth = 1
        barChartView.leftAxis.axisLineWidth = 1
        barChartView.leftAxis.gridLineWidth = 1
        barChartView.rightAxis.gridLineWidth = 1
        barChartView.leftAxis.setLabelCount(3, force: true)
    }
    
    private func getValues(with data: [Float], width: Double) -> [BarChartDataEntry] {
        var x: Double = 0
        let values = data.compactMap({Double($0)})
        var yValues: [BarChartDataEntry] = []
        for value in values {
            yValues.append(BarChartDataEntry(x: x, yValues: [value], icon: nil))
            x += width
        }
        return yValues
    }
    
    private func setUpChartLegend(for count: Int, labels: [String]) {
        var entrys = [LegendEntry]()
        let colors = getBarColors(for: count)
        for index in 0..<count where labels.count > index {
            entrys.append(LegendEntry(label: labels[index], form: .circle, formSize: 12, formLineWidth: 0, formLineDashPhase: 0, formLineDashLengths: nil, formColor: colors[index]))
        }
        barChartView.legend.setCustom(entries: entrys)
        barChartView.legend.font = UIFont(name: "SFProText-Regular", size: 10) ?? barChartView.leftAxis.labelFont
        barChartView.legend.textColor = UIColor(hex: 0xAEAEB2)
        
        barChartView.legendRenderer.computeLegend(data: barChartView.data!)
        barChartView.legend.verticalAlignment = .bottom
        barChartView.legend.xEntrySpace = ((barChartView.frame.width - barChartView.legend.neededWidth) / 4) - 12
        barChartView.legend.yEntrySpace = 5
        barChartView.legend.orientation = .horizontal
    }

    private func getBarColors(for entriesSize: Int) -> [UIColor] {
        var colors = [UIColor]()
        let hueRange = 360
        //let entriesSize = 10
        let step = hueRange  / entriesSize
        for i in 1...entriesSize {
            let HSVColor = HSV.rgb(h: Float(step * i))
            let color = UIColor(red: CGFloat(HSVColor.r), green: CGFloat(HSVColor.g), blue: CGFloat(HSVColor.b), alpha: 1.0)
            colors.append(color)
        }
        return colors
    }
    
    private func calculateBarWidth(barCount: Int) -> Double {
        let width = Double(barChartView.frame.width)
        let floatBarCount = Double(barCount)
        let minUISupportedEntriesCount: Double = 6
        if floatBarCount <= minUISupportedEntriesCount {
            return 0.01 * (width / minUISupportedEntriesCount)
        } else {
            return width / floatBarCount
        }
    }
}

extension BarChartCell: ChartDimensions {
    var optimalHeight: CGFloat {
        return 294 + barChartView.legend.neededHeight
    }
}


class BarChartLeftAxisValueFormatter: NSObject, IAxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String.convertBigValueToString(value: value, for: true)
    }
}
