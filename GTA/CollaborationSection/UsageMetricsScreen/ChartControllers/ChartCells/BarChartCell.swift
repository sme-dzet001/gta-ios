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
        let yValues: [BarChartDataEntry] = getValues(with: chartData.values)
        let set = BarChartDataSet(entries: yValues, label: nil)
        set.drawIconsEnabled = true
        set.colors = getBarColors()
        let data = BarChartData(dataSet: set)
        data.setDrawValues(false)
        setUpAxis()
        barChartView.fitBars = true
        barChartView.data = data
        barChartView.extraBottomOffset = 13
        //barChartView.delegate = self
        let stackLabels = chartData.legends
        setUpChartLegend(for: yValues.count, labels: stackLabels)
    }
    
    private func setUpAxis() {
        let font = UIFont(name: "SFProText-Regular", size: 10) ?? barChartView.leftAxis.labelFont
        let axisColor = UIColor(hex: 0xE5E5EA)
        barChartView.leftAxis.labelFont = font
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
        
    }
    
    private func getValues(with data: [Float]) -> [BarChartDataEntry] {
        var x: Double = 0
        let values = data.compactMap({Double($0)}) //data.forEach({Double($0)})// [Double(5293), Double(4866), Double(5204), Double(1112)]
        var yValues: [BarChartDataEntry] = []
        for value in values {
            yValues.append(BarChartDataEntry(x: x, yValues: [value], icon: nil))
            x += 0.85
        }
        return yValues
    }
    
    private func setUpChartLegend(for count: Int, labels: [String]) {
        var entrys = [LegendEntry]()
        let colors = getBarColors()
        for index in 0..<count where labels.count > index {
            entrys.append(LegendEntry(label: labels[index], form: .circle, formSize: 12, formLineWidth: 0, formLineDashPhase: 0, formLineDashLengths: nil, formColor: colors[index]))
        }
        barChartView.legend.setCustom(entries: entrys)
        barChartView.legend.font = UIFont(name: "SFProText-Regular", size: 10) ?? barChartView.leftAxis.labelFont
        barChartView.legend.textColor = UIColor(hex: 0xAEAEB2)
        
        barChartView.legendRenderer.computeLegend(data: barChartView.data!)
        barChartView.legend.verticalAlignment = .bottom
        barChartView.legend.xEntrySpace = ((barChartView.frame.width - barChartView.legend.neededWidth) / 4) - 12
        barChartView.legend.orientation = .horizontal
    }

    private func getBarColors() -> [UIColor]{
        // hardcode
        return [UIColor(red: 66.0 / 255.0, green: 141.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0), UIColor(red: 106.0 / 255.0, green: 26.0 / 255.0, blue: 128.0 / 255.0, alpha: 1.0), UIColor(red: 184.0 / 255.0, green: 73.0 / 255.0, blue: 146.0 / 255.0, alpha: 1.0), UIColor(red: 240.0 / 255.0, green: 156.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0), UIColor(red: 66.0 / 255.0, green: 141.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0), UIColor(red: 106.0 / 255.0, green: 26.0 / 255.0, blue: 128.0 / 255.0, alpha: 1.0), UIColor(red: 184.0 / 255.0, green: 73.0 / 255.0, blue: 146.0 / 255.0, alpha: 1.0), UIColor(red: 240.0 / 255.0, green: 156.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0), UIColor(red: 66.0 / 255.0, green: 141.0 / 255.0, blue: 247.0 / 255.0, alpha: 1.0), UIColor(red: 106.0 / 255.0, green: 26.0 / 255.0, blue: 128.0 / 255.0, alpha: 1.0), UIColor(red: 184.0 / 255.0, green: 73.0 / 255.0, blue: 146.0 / 255.0, alpha: 1.0), UIColor(red: 240.0 / 255.0, green: 156.0 / 255.0, blue: 105.0 / 255.0, alpha: 1.0)]
    }
}

extension BarChartCell: ChartDimensions {
    var optimalHeight: CGFloat {
        return 294
    }
}
