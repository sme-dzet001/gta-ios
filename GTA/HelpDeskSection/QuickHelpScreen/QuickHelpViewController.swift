//
//  QuickHelpViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class QuickHelpViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var quickHelpDataSource = [QuickHelpData]()
    private var expandedRowsIndex = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setHardCodeData()
        setUpTableView()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Quick Help"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.register(UINib(nibName: "QuickHelpCell", bundle: nil), forCellReuseIdentifier: "QuickHelpCell")
    }
    
    private func setHardCodeData() {
        let quickHelpItem = QuickHelpData(question: "What is Global Service Desk?", answer: "From end of August 2020, Swedish authorities are performing daily data consolidation leading to data retro-corrections. From week 38, the Swedish Public Health Agency will update COVID-19 daily data four times per week on Tuesday–Friday. Hence, the cumulative figures and related outputs include cases and deaths from the previous 14 days with available data at the time of data collection.")
        quickHelpDataSource = Array(repeating: quickHelpItem, count: 7)
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension QuickHelpViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quickHelpDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "QuickHelpCell", for: indexPath) as? QuickHelpCell {
            let cellDataSource = quickHelpDataSource[indexPath.row]
            cell.delegate = self
            cell.setUpCell(with: cellDataSource, expandBtnType: expandedRowsIndex.contains(indexPath.row) ? .minus : .plus)
            return cell
        }
        return UITableViewCell()
    }
    
    private func heightForAnswerAt(indexPath: IndexPath) -> CGFloat {
        guard let answerTextFont = UIFont(name: "SFProText-Light", size: 16) else { return 0 }
        let answerText = quickHelpDataSource[indexPath.row].answer
        let textHeight = answerText.height(width: view.frame.width - 48, font: answerTextFont)
        return textHeight
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedRowsIndex.contains(indexPath.row) {
            return 80 + heightForAnswerAt(indexPath: indexPath)
        }
        return 64
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedRowsIndex.contains(indexPath.row) {
            return 80 + heightForAnswerAt(indexPath: indexPath)
        }
        return 64
    }
    
}

extension QuickHelpViewController: QuickHelpCellDelegate {
    
    func quickHelpCellTapped(_ cell: QuickHelpCell, animationDuration: Double) {
        guard let cellIndex = tableView.indexPath(for: cell)?.row else { return }
        if expandedRowsIndex.contains(cellIndex) {
            // hideAnimation
            cell.expandButton.setImage(UIImage(named: "plus_icon"), for: .normal)
            UIView.animate(withDuration: animationDuration, animations: { [weak self] in
                guard let self = self else { return }
                CATransaction.begin()
                self.tableView.beginUpdates()
                self.expandedRowsIndex.removeAll { $0 == cellIndex }
            }) { (_) in
                self.tableView.endUpdates()
                CATransaction.commit()
            }
        } else {
            // showAnimation
            cell.expandButton.setImage(UIImage(named: "minus_icon"), for: .normal)
            UIView.animate(withDuration: animationDuration, animations: { [weak self] in
                guard let self = self else { return }
                CATransaction.begin()
                self.tableView.beginUpdates()
                self.expandedRowsIndex.append(cellIndex)
            }) { (_) in
                self.tableView.endUpdates()
                CATransaction.commit()
                if let cellIndexPath = self.tableView.indexPath(for: cell) {
                    self.tableView.scrollToRow(at: cellIndexPath, at: .none, animated: true)
                }
            }
        }
    }
}

struct QuickHelpData {
    var question: String
    var answer: String
}

enum ExpandButtonType {
    case plus
    case minus
}
