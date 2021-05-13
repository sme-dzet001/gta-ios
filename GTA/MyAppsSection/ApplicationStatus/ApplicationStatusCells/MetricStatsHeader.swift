//
//  MetricStatsHeader.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 18.11.2020.
//

import UIKit

protocol MetricStatsHeaderDelegate: AnyObject {
    func periodWasChanged(_ header: MetricStatsHeader, to period: MetricsPeriod)
}

class MetricStatsHeader: UIView {

    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var barChartView: StatsBarChart!
    @IBOutlet weak var periodSubtitleLabel: UILabel!
    
    weak var delegate: MetricStatsHeaderDelegate?
    
    class func instanceFromNib() -> MetricStatsHeader {
        let header = UINib(nibName: "MetricStatsHeader", bundle: nil).instantiate(withOwner: self, options: nil).first as! MetricStatsHeader
        return header
    }
    
    func setUpHeaderData(selectedPeriod: MetricsPeriod) {
        switch selectedPeriod {
        case .daily:
            segmentedControl.selectedSegmentIndex = 0
            periodSubtitleLabel.text = "Day"
        case .weekly:
            segmentedControl.selectedSegmentIndex = 1
            periodSubtitleLabel.text = "Week"
        case .monthly:
            segmentedControl.selectedSegmentIndex = 2
            periodSubtitleLabel.text = "Month"
        }
    }
    
    func setChartData(selectedPeriod: MetricsPeriod, data: MetricsData?) {
        switch selectedPeriod {
        case .daily:
            barChartView.setDataList(with: data?.dailyData.reversed() ?? [])
        case .weekly:
            barChartView.setDataList(with: data?.weeklyData.reversed() ?? [])
        case .monthly:
            barChartView.setDataList(with: data?.monthlyData.reversed() ?? [])
        }
    }

    @IBAction func segmentedControlValueDidChanged(_ sender: UISegmentedControl) {
        let periodsSubtitles = ["Day", "Week", "Month"]
        periodSubtitleLabel.text = periodsSubtitles[sender.selectedSegmentIndex]
        var selectedPeriod: MetricsPeriod
        if sender.selectedSegmentIndex == 0 {
            selectedPeriod = .daily
        } else if sender.selectedSegmentIndex == 1 {
            selectedPeriod = .weekly
        } else {
            selectedPeriod = .monthly
        }
        delegate?.periodWasChanged(self, to: selectedPeriod)
    }
    
}
