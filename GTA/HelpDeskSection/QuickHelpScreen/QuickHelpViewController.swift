//
//  QuickHelpViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class QuickHelpViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var dataProvider: HelpDeskDataProvider?
    private var expandedRowsIndex = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadQuickHelpData()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Quick Help"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    private func setUpTableView() {
        tableView.register(UINib(nibName: "QuickHelpCell", bundle: nil), forCellReuseIdentifier: "QuickHelpCell")
    }
    
    private func loadQuickHelpData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.quickHelpDataIsEmpty {
            activityIndicator.startAnimating()
            tableView.isHidden = true
        }
        dataProvider.getQuickHelpData { [weak self] (errorCode, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
                } else {
                    self?.displayError(errorMessage: "Error was happened!")
                }
            }
        }
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension QuickHelpViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.quickHelpData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "QuickHelpCell", for: indexPath) as? QuickHelpCell {
            let data = dataProvider?.quickHelpData ?? []
            let cellDataSource = data[indexPath.row]
            cell.delegate = self
            let answerEncoded = cellDataSource.answer
            let answerDecoded = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded)
            cell.setUpCell(question: cellDataSource.question, answer: answerDecoded, expandBtnType: expandedRowsIndex.contains(indexPath.row) ? .minus : .plus)
            return cell
        }
        return UITableViewCell()
    }
    
    private func heightForAnswerAt(indexPath: IndexPath) -> CGFloat {
        let data = dataProvider?.quickHelpData ?? []
        guard let answerEncoded = data[indexPath.row].answer else { return 0 }
        let answerDecoded = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded)
        guard let answerBody = answerDecoded?.htmlToAttributedString else { return 0 }
        let textHeight = answerBody.height(containerWidth: view.frame.width - 48)
        return textHeight
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedRowsIndex.contains(indexPath.row) {
            return 64 + heightForAnswerAt(indexPath: indexPath)
        }
        return 64
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedRowsIndex.contains(indexPath.row) {
            return 64 + heightForAnswerAt(indexPath: indexPath)
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

enum ExpandButtonType {
    case plus
    case minus
}
