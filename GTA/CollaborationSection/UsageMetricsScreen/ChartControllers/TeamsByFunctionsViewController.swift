//
//  TeamsByFunctionsViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 14.07.2021.
//

import UIKit
import Charts

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

class TeamsByFunctionsViewController: LineChartViewController {
    
    @IBOutlet var selectorBtns: [ChartDataSourceSelectionButton]!
    @IBOutlet weak var titleLabel: UILabel!
    
    var chartsData: TeamsByFunctionsLineChartData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateData()
    }
    
    private func updateData() {
        dataSourceIdx = 0
        titleLabel.text = chartsData?.title
    }
    
    var dataSourceIdx: Int = 0 {
        didSet {
            updateLabels()
            updateChartData()
            updateSelectorBtns()
        }
    }
    
    override var lineChartData: [(period: String?, value: Int?)] {
        let count = chartsData?.data?.count ?? 0
        guard count > dataSourceIdx else { return [(period: String?, value: Int?)]() }
        let values = chartsData?.data?[dataSourceIdx] ?? []
        return values.map({ return (period: $0.formattedLegend, value: $0.value) })
    }
    
    @IBAction func dataSourceSelectorBtnTapped(_ sender: ChartDataSourceSelectionButton) {
        dataSourceIdx = sender.tag - 500
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
}

extension TeamsByFunctionsViewController: ChartDimensions {
    var optimalHeight: CGFloat {
        return 370
    }
}

extension TeamsByFunctionsViewController: TeamsByFunctionsDataChangedDelegate {
    func teamsByFunctionsDataChanged(newData: TeamsByFunctionsLineChartData?) {
        guard chartsData != newData else { return }
        chartsData = newData
        configureChart(isFirstTime: false)
        updateData()
    }
    
    
}
