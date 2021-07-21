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
    
    var data: [String : [[TeamsByFunctionsDataEntry]]]?
    private var chartsData: [[TeamsByFunctionsDataEntry]]? {
        guard let key = data?.keys.first else { return nil }
        return data?[key]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSelectorBtns()
        titleLabel.text = data?.keys.first
    }
    
    var dataSourceIdx: Int = 0 {
        didSet {
            updateLabels()
            updateChartData()
            updateSelectorBtns()
        }
    }
    
    override var lineChartData: [(period: String?, value: Int?)] {
        let count = chartsData?.count ?? 0
        guard count > dataSourceIdx else { return [(period: String?, value: Int?)]() }
        let values = chartsData?[dataSourceIdx] ?? []
        return values.map({ return (period: $0.formattedLegend, value: $0.value) })
    }
    
    @IBAction func dataSourceSelectorBtnTapped(_ sender: ChartDataSourceSelectionButton) {
        dataSourceIdx = sender.tag - 500
    }
    
    func updateSelectorBtns() {
        for selectorBtn in selectorBtns {
            selectorBtn.isActive = (selectorBtn.tag - 500) == dataSourceIdx
        }
    }
}

extension TeamsByFunctionsViewController: ChartDimensions {
    var optimalHeight: CGFloat {
        return 370
    }
}
