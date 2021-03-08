//
//  QuickHelpViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class QuickHelpViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var dataProvider: HelpDeskDataProvider?
    private var expandedRowsIndex = [Int]()
    private var lastUpdateDate: Date?
    var isTipsAndTricks: Bool = false
    var appName: String?
    private lazy var appsDataProvider: MyAppsDataProvider = MyAppsDataProvider()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = UIColor.white
        if isTipsAndTricks {
            loadTipsAndTricks()
            return
        }
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadQuickHelpData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAnimation()
    }
    
    private func loadTipsAndTricks() {
        startAnimation()
        appsDataProvider.getAppTipsAndTricks(for: appName) {[weak self] (errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                //self?.activityIndicator.stopAnimating()
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    self?.tableView.reloadData()
                } else {
                    self?.errorLabel.isHidden = !(self?.appsDataProvider.tipsAndTricksData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func startAnimation() {
        self.navigationController?.addAndCenteredActivityIndicator(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        tableView.isHidden = true
    }
    
    private func stopAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = !isTipsAndTricks ? "Quick Help" : "\(appName ?? "") - Tips & Tricks"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    private func setUpTableView() {
        tableView.register(UINib(nibName: "QuickHelpCell", bundle: nil), forCellReuseIdentifier: "QuickHelpCell")
    }
    
    private func loadQuickHelpData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.quickHelpDataIsEmpty {
            startAnimation()
//            activityIndicator.startAnimating()
//            errorLabel.isHidden = true
//            tableView.isHidden = true
        }
        dataProvider.getQuickHelpData { [weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                //self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    self?.errorLabel.isHidden = !dataProvider.quickHelpDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
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
        if isTipsAndTricks {
            return appsDataProvider.tipsAndTricksData.count
        }
        return dataProvider?.quickHelpData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "QuickHelpCell", for: indexPath) as? QuickHelpCell {
            let data = !isTipsAndTricks ? dataProvider?.quickHelpData ?? [] : appsDataProvider.tipsAndTricksData
            let cellDataSource = data[indexPath.row]
            cell.delegate = self
            let answerEncoded = cellDataSource.answer
            let answerDecoded = !isTipsAndTricks ? dataProvider?.formQuickHelpAnswerBody(from: answerEncoded) : appsDataProvider.formTipsAndTricksAnswerBody(from: answerEncoded)
            if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
                answerDecoded?.setFontFace(font: neededFont)
            }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            answerDecoded?.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, answerDecoded?.length ?? 0))
            cell.setUpCell(question: cellDataSource.question, answer: answerDecoded, expandBtnType: expandedRowsIndex.contains(indexPath.row) ? .minus : .plus)
            return cell
        }
        return UITableViewCell()
    }
    
    private func heightForAnswerAt(indexPath: IndexPath) -> CGFloat {
        let data = !isTipsAndTricks ? dataProvider?.quickHelpData ?? [] : appsDataProvider.tipsAndTricksData
        guard let answerEncoded = data[indexPath.row].answer else { return 0 }
        let answer = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded) ?? appsDataProvider.formTipsAndTricksAnswerBody(from: answerEncoded)
        guard let answerBody = answer else { return 0 }
        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
            answerBody.setFontFace(font: neededFont)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        answerBody.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, answerBody.length))
        let textHeight = answerBody.height(containerWidth: view.frame.width - 48)
        let bottomMargin: CGFloat = 8
        return textHeight + bottomMargin
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
    
    func openUrl(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
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
