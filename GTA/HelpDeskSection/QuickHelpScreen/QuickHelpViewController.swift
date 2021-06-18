//
//  QuickHelpViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 01.12.2020.
//

import UIKit

class QuickHelpViewController: UIViewController {
    
    @IBOutlet weak var titleStackView: UIStackView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
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
        if screenType == .appTipsAndTricks {
            navBarView.isHidden = false
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
        addErrorLabel(errorLabel, isGSD: screenType != .collaborationTipsAndTricks)
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard screenType != .quickHelp else { return }
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func loadQuickHelpData() {
        guard let dataProvider = dataProvider else { return }
        if dataProvider.quickHelpDataIsEmpty {
            startAnimation()
        }
        dataProvider.getQuickHelpData { [weak self] (dataWasChanged, errorCode, error, fromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !fromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    if dataProvider.quickHelpDataIsEmpty {
                        self?.tableView.reloadData()
                    }
                    self?.errorLabel.isHidden = !dataProvider.quickHelpDataIsEmpty
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func loadAppTipsAndTricks() {
        if self.appsDataProvider?.tipsAndTricksData[appName ?? ""] == nil || (appsDataProvider?.tipsAndTricksData[appName ?? ""]?.isEmpty ?? true){
            startAnimation()
        }
        appsDataProvider?.getAppTipsAndTricks(for: appName) {[weak self] (dataWasChanged, errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    if self?.appsDataProvider?.tipsAndTricksData[self?.appName ?? ""]?.isEmpty ?? true {
                        self?.tableView.reloadData()
                    }
                    self?.errorLabel.isHidden = !(self?.appsDataProvider?.tipsAndTricksData[self?.appName ?? ""]?.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func loadCollaborationTipsAndTricks() {
        if collaborationDataProvider?.tipsAndTricksData == nil || (collaborationDataProvider?.tipsAndTricksData.isEmpty ?? true) {
            startAnimation()
        }
        collaborationDataProvider?.getTipsAndTricks(appSuite: appName ?? "", completion: {[weak self] (dataWasChanged, errorCode, error, fromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !fromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    if self?.collaborationDataProvider?.tipsAndTricksData.isEmpty ?? true {
                        self?.tableView.reloadData()
                    }
                    self?.errorLabel.isHidden = !(self?.collaborationDataProvider?.tipsAndTricksData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        })
    }
    
    private func startAnimation() {
        self.addLoadingIndicator(activityIndicator, isGSD: screenType != .collaborationTipsAndTricks)
        activityIndicator.startAnimating()
        errorLabel.isHidden = true
        tableView.alpha = 0// = true
    }
    
    private func stopAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func setUpNavigationItem() {
        if screenType == .appTipsAndTricks {
            titleLabel.text = appName ?? ""
            subTitleLabel.text = "Tips & Tricks"
            if UIDevice.current.iPhone7_8 || UIDevice.current.iPhone5_se {
                titleStackView.spacing = 5
                self.view.layoutIfNeeded()
            }
            return
        }
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
            return appsDataProvider?.tipsAndTricksData[appName ?? ""] ?? []
        default:
            return dataProvider?.quickHelpData ?? []
        }
    }
    
    @IBAction func backNavButtonPressed(_ sender: Any) {
        backPressed()
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension QuickHelpViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getHelpData().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "QuickHelpCell", for: indexPath) as? QuickHelpCell {
            let data: [QuickHelpDataProtocol] = getHelpData()
            guard data.count > indexPath.row else { return UITableViewCell() }
            let cellDataSource = data[indexPath.row]
            cell.delegate = self
            let answerEncoded = cellDataSource.answer
            let answerDecoded = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded) ?? appsDataProvider?.formTipsAndTricksAnswerBody(from: answerEncoded) ?? collaborationDataProvider?.formAnswerBody(from: answerEncoded, isTipsAndTricks: true)
            if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
                answerDecoded?.setFontFace(font: neededFont)
            }
            answerDecoded?.setParagraphStyleParams(lineSpacing: 8)
            let questionFormatted = formAttributedQuestion(from: cellDataSource.question ?? "")
            cell.setUpCell(question: questionFormatted, questionLabelHeight: heightForQuestionAt(indexPath: indexPath) - 32, answer: answerDecoded, expandBtnType: expandedRowsIndex.contains(indexPath.row) ? .collapse : .expand)
            return cell
        }
        return UITableViewCell()
    }
    
    func formAttributedQuestion(from question: String) -> NSMutableAttributedString? {
        guard let neededFont = UIFont(name: "SFProText-Semibold", size: 16) else { return nil }
        let fontAttributes = [NSAttributedString.Key.font: neededFont]
        var question = question
        if question.first == " " {
            question.removeFirst()
        }
        let attributedQuestion = NSMutableAttributedString(string: question, attributes: fontAttributes)
        attributedQuestion.setFontFace(font: neededFont)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        attributedQuestion.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedQuestion.length))
        return attributedQuestion
    }
    
    private func heightForQuestionAt(indexPath: IndexPath) -> CGFloat {
        let data: [QuickHelpDataProtocol] = getHelpData()
        guard data.count > indexPath.row else { return 0 }
        guard let question = data[indexPath.row].question else { return 0 }
        guard let attributedQuestion = formAttributedQuestion(from: question) else { return 0 }
        let questionLabelLeftIndent: CGFloat = 24
        let expandBtnRightIndent: CGFloat = 20
        let expandBtnWidth: CGFloat = 35
        let expandBtnSpace: CGFloat = 8
        let questionLabelAdditionalSpace = questionLabelLeftIndent + expandBtnRightIndent + expandBtnWidth + expandBtnSpace
        let textHeight = attributedQuestion.height(containerWidth: view.frame.width - questionLabelAdditionalSpace)
        let topMargin: CGFloat = 16
        let bottomMargin: CGFloat = 32
        let res = textHeight + topMargin + bottomMargin
        return (res > 64) ? res : 64
    }
    
    private func heightForAnswerAt(indexPath: IndexPath) -> CGFloat {
        let data: [QuickHelpDataProtocol] = getHelpData()
        guard data.count > indexPath.row else { return 0 }
        guard let answerEncoded = data[indexPath.row].answer else { return 0 }
        let answer = dataProvider?.formQuickHelpAnswerBody(from: answerEncoded) ?? appsDataProvider?.formTipsAndTricksAnswerBody(from: answerEncoded) ?? collaborationDataProvider?.formAnswerBody(from: answerEncoded)
        guard let answerBody = answer else { return 0 }
        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
            answerBody.setFontFace(font: neededFont)
        }
        answerBody.setParagraphStyleParams(lineSpacing: 8)
        let textHeight = answerBody.height(containerWidth: view.frame.width - 48)
        let bottomMargin: CGFloat = 32
        return textHeight + bottomMargin
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return getCellHeight(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return getCellHeight(for: indexPath)
    }
    
    private func getCellHeight(for indexPath: IndexPath) -> CGFloat {
        if expandedRowsIndex.contains(indexPath.row) {
            return UITableView.automaticDimension// expandedCellHeight[indexPath] ?? heightForQuestionAt(indexPath: indexPath) + heightForAnswerAt(indexPath: indexPath)
        }
        return heightForQuestionAt(indexPath: indexPath)
    }
    
}

extension QuickHelpViewController: QuickHelpCellDelegate {

    func quickHelpCellTapped(_ cell: QuickHelpCell, animationDuration: Double) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let cellIndex = tableView.indexPath(for: cell)?.row else { return }
        guard getHelpData().count > cellIndex else { return }
        if expandedRowsIndex.contains(cellIndex) {
            // hideAnimation
            cell.expandButton.setImage(UIImage(named: "disclosure_arrow_down"), for: .normal)
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
            cell.expandButton.setImage(UIImage(named: "disclosure_arrow_up"), for: .normal)
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
    case expand
    case collapse
}

enum QuickHelpScreenType {
    case quickHelp
    case collaborationTipsAndTricks
    case appTipsAndTricks
}
