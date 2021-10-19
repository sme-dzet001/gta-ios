//
//  TipsAndTricksViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 02.09.2021.
//

import UIKit

class TipsAndTricksViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerSeparator: UIView!
    
    var dataProvider: CollaborationDataProvider?
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    private var cellForAnimation: TipsAndTricksTableViewCell?
    private var expandedRowsIndex = [Int]()
    private var dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        loadCollaborationTipsAndTricks()
    }
    
    private func startAnimation() {
        guard dataProvider?.tipsAndTricksData.isEmpty ?? true  else { return }
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.addLoadingIndicator(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        if !(dataProvider?.tipsAndTricksData.isEmpty ?? true) {
            errorLabel.isHidden = true
            self.tableView.alpha = 1
        }
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = tableView.menuButtonContentInset
        tableView.register(UINib(nibName: "TipsAndTricksTableViewCell", bundle: nil), forCellReuseIdentifier: "TipsAndTricksTableViewCell")
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "Tips & Tricks"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        if #available(iOS 15.0, *) {
            headerSeparator.isHidden = false
        }
    }
    
    private func loadCollaborationTipsAndTricks() {
        if dataProvider?.tipsAndTricksData == nil || (dataProvider?.tipsAndTricksData.isEmpty ?? true) {
            startAnimation()
        }
        dataProvider?.getTipsAndTricks(appSuite: "Office365", completion: {[weak self] (dataWasChanged, errorCode, error, fromCache) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.errorLabel.isHidden = true
                    self?.tableView.alpha = 1
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    if self?.dataProvider?.tipsAndTricksData.isEmpty ?? true {
                        self?.tableView.reloadData()
                    }
                    self?.errorLabel.isHidden = !(self?.dataProvider?.tipsAndTricksData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        })
    }
    
    func formAttributedQuestion(from question: String, font: UIFont?) -> NSMutableAttributedString? {
        guard let neededFont = font ?? UIFont(name: "SFProText-Semibold", size: 16) else { return nil }
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
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension TipsAndTricksViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.tipsAndTricksData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard (dataProvider?.tipsAndTricksData.count ?? 0) > indexPath.row else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TipsAndTricksTableViewCell", for: indexPath) as? TipsAndTricksTableViewCell
        let cellDataSource = dataProvider?.tipsAndTricksData[indexPath.row]
        cell?.delegate = self
        
        let questionFormatted = formAttributedQuestion(from: cellDataSource?.question ?? "", font: cell?.titleLabel.font)
        let answerDecoded = decodedAnswer(answer: cellDataSource?.answer ?? "")
        answerDecoded.setParagraphStyleParams(lineSpacing: 8)
        
        cell?.fullText = answerDecoded
        cell?.mainImageView.image = UIImage(named: "testTipsImage")
        cell?.titleLabel.attributedText = questionFormatted
        cell?.descriptionLabel.attributedText = answerDecoded
        if !expandedRowsIndex.contains(indexPath.row) {
            cell?.setCollapse()
        } else {
            cell?.descriptionLabel.attributedText = answerDecoded
            cell?.descriptionLabel.numberOfLines = 0
            cell?.descriptionLabel.sizeToFit()
        }
    
        cell?.imageUrl = cellDataSource?.banner
        let imageURL = dataProvider?.formImageURL(from: cellDataSource?.banner) ?? ""
        let url = URL(string: imageURL)
        if imageURL.isEmptyOrWhitespace() {
            cell?.mainImageView.image = UIImage(named: "whatsNewPlaceholder")
        } else if let url = url, imageURL.contains(".gif") {
            cell?.activityIndicator.startAnimating()
            cell?.mainImageView.sd_setImage(with: url, placeholderImage: nil, options: .refreshCached, completed: { img, err, cacheType, _ in
                if let _ = err, (err! as NSError).code != 2002 {
                    cell?.activityIndicator.stopAnimating()
                    cell?.mainImageView.image = UIImage(named: "whatsNewPlaceholder")
                } else if let _ = img {
                    cell?.activityIndicator.stopAnimating()
                }
                cell?.mainImageView.autoPlayAnimatedImage = false
            })
        } else {
            cell?.mainImageView.kf.indicatorType = .activity
            cell?.mainImageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                switch result {
                case .success(let resData):
                    if !imageURL.contains(".gif") {
                       // cell?.mainImageView.setImage(resData.image)
                        cell?.mainImageView.image = resData.image
                    }
                case .failure(let error):
                    if !error.isNotCurrentTask {
                        cell?.mainImageView.image = UIImage(named: "whatsNewPlaceholder")
                    }
                }
            })
        }
        
        return cell ?? UITableViewCell()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        startAnimationAfterScroll()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startAnimationAfterScroll()
    }
    
    private func startAnimationAfterScroll() {
        guard let _ = cellForAnimation, tableView.visibleCells.contains(cellForAnimation!) else { return }
        cellForAnimation?.mainImageView.startAnimating()
    }
    private func decodedAnswer(answer: String) -> NSMutableAttributedString {
        let answerEncoded = answer
        let answerDecoded = dataProvider?.formAnswerBody(from: answerEncoded, isTipsAndTricks: true)
        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
            answerDecoded?.setFontFace(font: neededFont)
        }
        return answerDecoded ?? NSMutableAttributedString(string: "")
    }
    
}

extension TipsAndTricksViewController : TappedLabelDelegate {
    func moreButtonDidTapped(in cell: UITableViewCell) {
        guard let cell = cell as? TipsAndTricksTableViewCell else { return }
        guard let cellIndex = tableView.indexPath(for: cell) else { return }
        guard (dataProvider?.collaborationNewsData.count ?? 0) > cellIndex.row else { return }
        if !tableView.dataHasChanged {
            UIView.setAnimationsEnabled(false)
            self.dispatchGroup.enter()
            let answer = dataProvider?.tipsAndTricksData[cellIndex.row].answer
            cell.descriptionLabel.attributedText = decodedAnswer(answer: answer ?? "")
            cell.descriptionLabel.numberOfLines = 0
            self.tableView.reloadData()
            self.dispatchGroup.leave()
        } else {
            tableView.reloadData()
            return
        }
        if !expandedRowsIndex.contains(cellIndex.row) {
            expandedRowsIndex.append(cellIndex.row)
        }
        if cell.bounds.height > self.tableView.frame.height {
            self.tableView.scrollToRow(at: cellIndex, at: .top, animated: true)
        } else {
            self.tableView.scrollToRow(at: cellIndex, at: .none, animated: true)
        }
        UIView.setAnimationsEnabled(true)
    }
    
    func openUrl(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            displayError(errorMessage: "Something went wrong", title: nil)
        }
    }
    
}
