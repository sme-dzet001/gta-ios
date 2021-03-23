//
//  QuickHelpViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class QuickHelpViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var errorLabel: UILabel!
    
    private var errorLabel: UILabel = UILabel()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var dataProvider: HelpDeskDataProvider?
    private var expandedRowsIndex = [Int]()
    private var lastUpdateDate: Date?
    var screenType: QuickHelpScreenType = .quickHelp
    var appName: String?
    var appsDataProvider: MyAppsDataProvider?
    var collaborationDataProvider: CollaborationDataProvider? 

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel, isGSD: screenType == .quickHelp)
        navigationController?.navigationBar.barTintColor = UIColor.white
        switch screenType {
        case .appTipsAndTricks:
            loadAppTipsAndTricks()
        case .collaborationTipsAndTricks:
            loadCollaborationTipsAndTricks()
        default:
            if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
                loadQuickHelpData()
            }
        }
//        if isTipsAndTricks {
//            loadCollaborationTipsAndTricks()
//        }
//        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
//            loadQuickHelpData()
//        }
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
    
    private func loadAppTipsAndTricks() {
        if self.appsDataProvider?.tipsAndTricksData == nil || (appsDataProvider?.tipsAndTricksData.isEmpty ?? true){
            startAnimation()
        }
        appsDataProvider?.getAppTipsAndTricks(for: appName) {[weak self] (dataWasChanged, errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                //self?.activityIndicator.stopAnimating()
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    self?.errorLabel.isHidden = !(self?.appsDataProvider?.tipsAndTricksData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func loadCollaborationTipsAndTricks() {
        if collaborationDataProvider?.tipsAndTricksData == nil || (collaborationDataProvider?.tipsAndTricksData.isEmpty ?? true) {
            startAnimation()
        }
        collaborationDataProvider?.getTipsAndTricks(appSuite: appName ?? "", completion: {[weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                //self?.activityIndicator.stopAnimating()
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = Date().addingTimeInterval(60)
                    self?.errorLabel.isHidden = true
                    self?.tableView.isHidden = false
                    //self?.tableView.reloadData()
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    self?.errorLabel.isHidden = !(self?.collaborationDataProvider?.tipsAndTricksData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        })
    }
    
    private func startAnimation() {
        self.addLoadingIndicator(activityIndicator, isGSD: screenType == .quickHelp)
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        tableView.isHidden = true
    }
    
    private func stopAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func setUpNavigationItem() {
        var title = ""
        switch screenType {
        case .quickHelp:
            title = "Quick Help"
        case .appTipsAndTricks:
            title = "\(appName ?? "")\nTips & Tricks"
        case .collaborationTipsAndTricks:
            title = "Tips & Tricks"
        }
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = title
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    private func setUpTableView() {
        tableView.register(UINib(nibName: "QuickHelpCell", bundle: nil), forCellReuseIdentifier: "QuickHelpCell")
    }
    
    private func getHelpData() -> [QuickHelpDataProtocol] {
        switch screenType {
        case .collaborationTipsAndTricks:
            return collaborationDataProvider?.tipsAndTricksData ?? []
        case .appTipsAndTricks:
            return appsDataProvider?.tipsAndTricksData ?? []
        default:
            return dataProvider?.quickHelpData ?? []
        }
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension QuickHelpViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch screenType {
        case .appTipsAndTricks:
            return appsDataProvider?.tipsAndTricksData.count ?? 0
        case .collaborationTipsAndTricks:
            return collaborationDataProvider?.tipsAndTricksData.count ?? 0
        default:
            return dataProvider?.quickHelpData.count ?? 0
        }
//        if isTipsAndTricks {
//            return collaborationDataProvider.tipsAndTricksData.count
//        }
//        return dataProvider?.quickHelpData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "QuickHelpCell", for: indexPath) as? QuickHelpCell {
            let data: [QuickHelpDataProtocol] = getHelpData()
            let cellDataSource = data[indexPath.row]
            cell.delegate = self
            let answerEncoded = cellDataSource.answer
            let answerDecoded = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded) ?? appsDataProvider?.formTipsAndTricksAnswerBody(from: answerEncoded) ?? collaborationDataProvider?.formTipsAndTricksAnswerBody(from: answerEncoded)
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
        let data: [QuickHelpDataProtocol] = getHelpData()
        guard let answerEncoded = data[indexPath.row].answer else { return 0 }
        let answer = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded) ?? appsDataProvider?.formTipsAndTricksAnswerBody(from: answerEncoded) ?? collaborationDataProvider?.formTipsAndTricksAnswerBody(from: answerEncoded)
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

enum QuickHelpScreenType {
    case quickHelp
    case collaborationTipsAndTricks
    case appTipsAndTricks
}
