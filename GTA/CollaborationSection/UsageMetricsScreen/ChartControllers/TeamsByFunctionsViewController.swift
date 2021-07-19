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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSelectorBtns()
    }
    
    var dataSourceIdx: Int = 0 {
        didSet {
            updateLabels()
            updateChartData()
            updateSelectorBtns()
        }
    }
    
    override var lineChartData: [(period: String?, value: Int?)] {
        switch dataSourceIdx {
        case 1:
            return dataProvider?.teamsByFunctionsUsersData.map({ return (period: $0.formattedPeriod, value: $0.callCount) }) ?? []
        case 2:
            return dataProvider?.teamsByFunctionsUsersData.map({ return (period: $0.formattedPeriod, value: $0.privateChatMessageCount) }) ?? []
        case 3:
            return dataProvider?.teamsByFunctionsUsersData.map({ return (period: $0.formattedPeriod, value: $0.teamsChatMessageCount) }) ?? []
        default:
            return dataProvider?.teamsByFunctionsUsersData.map({ return (period: $0.formattedPeriod, value: $0.meetingCount) }) ?? []
        }
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
