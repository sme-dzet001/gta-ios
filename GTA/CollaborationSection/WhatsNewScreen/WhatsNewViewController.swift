//
//  WhatsNewViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit
import SDWebImage

class WhatsNewViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataProvider: CollaborationDataProvider?
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    private var cellForAnimation: WhatsNewCell?
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
        getWhatsNewData()
    }
    
    private func getWhatsNewData() {
        startAnimation()
        dataProvider?.getWhatsNewData(completion: {[weak self] (dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                if error != nil && errorCode != 200 {
                    self?.errorLabel.isHidden = !(self?.dataProvider?.collaborationNewsData.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
                if dataWasChanged {
                    self?.dispatchGroup.wait()
                    self?.tableView.reloadData()
                }
                self?.stopAnimation()
            }
        })
    }
    
    private func startAnimation() {
        guard dataProvider?.collaborationNewsData.isEmpty ?? true  else { return }
        self.tableView.alpha = 0
        errorLabel.isHidden = true
        self.addLoadingIndicator(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        if !(dataProvider?.collaborationNewsData.isEmpty ?? true) {
            errorLabel.isHidden = true
            self.tableView.alpha = 1
        }
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func setUpTableView() {
        let additionalSeparator: CGFloat = UIDevice.current.hasNotch ? 8 : 34
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: (tableView.frame.width * 0.133) + additionalSeparator, right: 0)
        tableView.register(UINib(nibName: "WhatsNewCell", bundle: nil), forCellReuseIdentifier: "WhatsNewCell")
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "What’s New"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension WhatsNewViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.collaborationNewsData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard (dataProvider?.collaborationNewsData.count ?? 0) > indexPath.row else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "WhatsNewCell", for: indexPath) as? WhatsNewCell
        let cellDataSource = dataProvider?.collaborationNewsData[indexPath.row]
        cell?.titleLabel.text = cellDataSource?.headline
        cell?.setDate(cellDataSource?.postDate)
        //cell?.subtitleLabel.text = cellDataSource?.subHeadline
        cell?.body = cellDataSource?.body
        let text = getDescriptionText(for: indexPath)
        cell?.delegate = self
        cell?.fullText = text
        if !expandedRowsIndex.contains(indexPath.row) {
            cell?.setCollapse()
        } else {
            cell?.descriptionLabel.attributedText = text
            cell?.descriptionLabel.numberOfLines = 0
            cell?.descriptionLabel.sizeToFit()
        }
        cell?.imageUrl = cellDataSource?.imageUrl
        let imageURL = dataProvider?.formImageURL(from: cellDataSource?.imageUrl) ?? ""
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (dataProvider?.collaborationNewsData.count ?? 0) > indexPath.row else { return }
//        let whatsNewMoreScreen = WhatsNewMoreViewController()
//        let cellDataSource = dataProvider?.collaborationNewsData[indexPath.row]
//        whatsNewMoreScreen.dataProvider = dataProvider
//        whatsNewMoreScreen.dataSource = cellDataSource
//        self.navigationController?.pushViewController(whatsNewMoreScreen, animated: true)
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cells = tableView.visibleCells as? [WhatsNewCell] else { return }
        if scrollView.contentOffset.y <= 0 {
            cells.forEach({$0.mainImageView.stopAnimating()})
            cells.first?.mainImageView.startAnimating()
            if let article = dataProvider?.collaborationNewsData.first?.body {
                dataProvider?.addArticle(article)
            }
            return
        }
        var distanceToCenter: CGFloat = 0
        for cell in cells {
            let row = dataProvider?.collaborationNewsData.firstIndex(where: {((cell.imageUrl ?? cell.body ?? "").contains($0.imageUrl ?? $0.body ?? ""))})
            guard let _ = row else { continue }
            let indexPath = IndexPath(row: row!, section: 0)
            let rect = self.tableView.rectForRow(at: indexPath)
            let currentDistanceToCenter = self.view.center.y - tableView.convert(rect, to: self.tableView.superview).origin.y
            if distanceToCenter == 0 || (distanceToCenter > currentDistanceToCenter && currentDistanceToCenter > 0) {
                distanceToCenter = currentDistanceToCenter
                cellForAnimation = cell
                if let article = dataProvider?.collaborationNewsData[indexPath.row].body {
                    dataProvider?.addArticle(article)
                }
            }
        }
        cells.forEach({$0.mainImageView.stopAnimating()})
    }

    private func getDescriptionText(for indexPath: IndexPath) -> NSMutableAttributedString? {
        guard (dataProvider?.collaborationNewsData.count ?? 0) > indexPath.row else { return nil }
        let cellDataSource = dataProvider?.collaborationNewsData[indexPath.row]
        let text = cellDataSource?.decodeBody
        if let neededFont = UIFont(name: "SFProText-Regular", size: 16) {
            text?.setFontFace(font: neededFont)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 22
        text?.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, text?.length ?? 0))
        return text
    }
    
}

extension WhatsNewViewController : TappedLabelDelegate {
    func moreButtonDidTapped(in cell: UITableViewCell) {
        guard let cell = cell as? WhatsNewCell else { return }
        guard let cellIndex = tableView.indexPath(for: cell) else { return }
        guard (dataProvider?.collaborationNewsData.count ?? 0) > cellIndex.row else { return }
        if !tableView.dataHasChanged {
            UIView.setAnimationsEnabled(false)
            self.dispatchGroup.enter()
            self.tableView.beginUpdates()
            cell.descriptionLabel.attributedText = self.getDescriptionText(for: cellIndex)
            cell.descriptionLabel.numberOfLines = 0
            self.tableView.endUpdates()
            self.dispatchGroup.leave()
        } else {
            tableView.reloadData()
            return
        }
        if !expandedRowsIndex.contains(cellIndex.row) {
            expandedRowsIndex.append(cellIndex.row)
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


protocol TappedLabelDelegate: AnyObject {
    func moreButtonDidTapped(in cell: UITableViewCell)
    func openUrl(_ url: URL)
}
