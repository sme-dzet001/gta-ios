//
//  BarChartCell.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 12.07.2021.
//

import UIKit
import Charts

class ActiveUsersByFunctionCell: UITableViewCell, VerticalBarChartDataChangedDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var barChartView: BarChartView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setUpBarChartView(with chartStructure: ChartStructure?) {
        DispatchQueue.main.async { [weak self] in
            guard let chartData = chartStructure else { return }
            self?.titleLabel.text = chartData.title
            let width = self?.calculateBarWidth(barCount: chartData.values.count)
            let yValues: [BarChartDataEntry] = self?.getValues(with: chartData.values, width: width ?? 0) ?? []
            guard !yValues.isEmpty else { return }
            let set = BarChartDataSet(entries: yValues, label: "")
            set.drawIconsEnabled = true
            set.colors = self?.getBarColors(for: yValues.count) ?? []
            set.highlightEnabled = false
            let data = BarChartData(dataSet: set)
            data.setDrawValues(false)
            data.barWidth = width ?? 1
            let axisMaximum = Double(chartData.values.max() ?? 0.0).getAxisMaximum()
            self?.setUpAxis(axisMaximum: axisMaximum)
            self?.barChartView.scaleXEnabled = false
            self?.barChartView.scaleYEnabled = false
            self?.barChartView.pinchZoomEnabled = false
            self?.barChartView.data = data
            self?.barChartView.fitBars = true
            self?.barChartView.extraBottomOffset = 13
            //barChartView.delegate = self
            let stackLabels = chartData.legends
            self?.setUpChartLegend(for: yValues.count, labels: stackLabels)
        }
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
        barChartView.chartDescription.enabled = false
        barChartView.xAxis.drawLabelsEnabled = false
        barChartView.rightAxis.drawLabelsEnabled = false
        barChartView.leftAxis.gridAntialiasEnabled = false
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.spaceBottom = 0
        barChartView.rightAxis.spaceBottom = 0
        barChartView.leftAxis.drawAxisLineEnabled = false
        barChartView.rightAxis.drawAxisLineEnabled = false
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
        guard let chartData = barChartView.data else { return }
        var entries = [LegendEntry]()
        let colors = getBarColors(for: count)
        for index in 0..<count where labels.count > index {
            let entry = LegendEntry(label: labels[index])
            entry.form = .circle
            entry.formSize = 12
            entry.formLineWidth = 0
            entry.formLineDashPhase = 0
            entry.formLineDashLengths = nil
            entry.formColor = colors[index]
            entries.append(entry)
        }
        barChartView.legend.setCustom(entries: entries)
        barChartView.legend.font = UIFont(name: "SFProText-Regular", size: 10) ?? barChartView.leftAxis.labelFont
        barChartView.legend.textColor = UIColor(hex: 0xAEAEB2)
        
        barChartView.legendRenderer.computeLegend(data: chartData)
        barChartView.legend.verticalAlignment = .bottom
        if count >= 4 {
            //let space = ((barChartView.frame.width - barChartView.legend.neededWidth) / CGFloat(4)) - 12
            barChartView.legend.xEntrySpace = 12//space > 0 ? space : barChartView.legend.xEntrySpace
        }
        barChartView.legend.yEntrySpace = 5
        barChartView.legend.orientation = .horizontal
        barChartView.legend.horizontalAlignment = count >= 4 ? .left : .center
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

extension ActiveUsersByFunctionCell: ChartDimensions {
    var optimalHeight: CGFloat {
        return 294 + barChartView.legend.neededHeight
    }
}


class BarChartLeftAxisValueFormatter: NSObject, AxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return String.convertBigValueToString(value: value, for: true)
    }
}
