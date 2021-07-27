//
//  BarChartCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.07.2021.
//

import UIKit
import Charts

class BarChartCell: UITableViewCell, VerticalBarChartDataChangedDelegate {

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
        let hardcodedColors = [UIColor(hex: 0xA6CEE3), UIColor(hex: 0x2493DE), UIColor(hex: 0xB2DF8A), UIColor(hex: 0x33A02C), UIColor(hex: 0xFB9A99),  UIColor(hex: 0xE31A1C), UIColor(hex: 0xFDBF6F), UIColor(hex: 0xFF7F00), UIColor(hex: 0xCAB2D6), UIColor(hex: 0x6A3D9A), UIColor(hex: 0x9AA1FF), UIColor(hex: 0x4C55D4), UIColor(hex: 0xEA4589), UIColor(hex: 0xBC2A66), UIColor(hex: 0xE390F1), UIColor(hex: 0xB656C6), UIColor(hex: 0x7A1859), UIColor(hex: 0xC9845E), UIColor(hex: 0x9C4612), UIColor(hex: 0xFFFF99), UIColor(hex: 0xFFEB32), UIColor(hex: 0xD0C9AA), UIColor(hex: 0x7E6442), UIColor(hex: 0xAEB5BC), UIColor(hex: 0x6E757C), UIColor(hex: 0x4AACB7), UIColor(hex: 0x3084AA), UIColor(hex: 0x85DAB5), UIColor(hex: 0x479D89), UIColor(hex: 0x326465)]
        for i in 0..<entriesSize {
            let index = hardcodedColors.count > i ? i : i - 30
            guard hardcodedColors.count > index else { return colors }
            colors.append(hardcodedColors[index])
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
