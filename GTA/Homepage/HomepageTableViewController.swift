//
//  HomepageTableViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit

protocol HomepageMainDelegate: AnyObject {
    func navigateToOfficeStatus()
}

class HomepageTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var blurView: UIView!
    
    weak var newsShowDelegate: NewsShowDelegate?
    
    var dataProvider: HomeDataProvider?
    var officeLoadingError: String?
    var officeLoadingIsEnabled = true
    var selectedFilterTab: FilterTabType = .all
         
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        blurView.addBlurToView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataLoadingStarted()
        let dataSource = getDataSource()
        if !dataSource.isEmpty && tableView.dataHasChanged {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            //tableView.reloadData()
        }
    }
    
    private func setAccessibilityIdentifiers() {
        guard let items = self.tabBarController?.tabBar.items else { return }
        for (index, _) in items.enumerated() {
            self.tabBarController?.tabBar.items?[index].accessibilityIdentifier = getIdentifierForTabbarIndex(index)
        }
    }
    
    private func getIdentifierForTabbarIndex(_ index: Int) -> String {
        switch index {
        case 0:
            return "TabBarHomeTab"
        case 1:
            return "TabBarServiceDeskTab"
        case 2:
            return "TabBarAppsTab"
        case 3:
            return "TabBarCollaborationTab"
        case 4:
            return "TabBarGeneralTab"
        default:
            return ""
        }
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "NewsTableViewCell", bundle: nil), forCellReuseIdentifier: "NewsTableViewCell")
        tableView.contentInset = tableView.menuButtonContentInset
        tableView.accessibilityIdentifier = "HomeScreenTableView"
    }
    
    func dataLoadingStarted() {
        guard isViewLoaded else { return }
        guard let _ = dataProvider else { return }
        guard dataProvider!.getNewsFeedInProgress else { return }
        let dataSource = getDataSource()
        if dataSource.isEmpty {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
        }
    }
    
    func dataLoadingFinished(dataWasChanged: Bool, errorCode: Int, error: Error?, isFromCache: Bool) {
        guard isViewLoaded else { return }
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        if error == nil && errorCode == 200 {
            errorLabel.isHidden = true
            if dataWasChanged { tableView.reloadData() }
        } else {
            let dataSource = getDataSource()
            let isNoData = dataSource.isEmpty
            if isNoData {
                tableView.reloadData()
            }
            errorLabel.isHidden = !isNoData
            errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
        }
    }
    
    deinit {
    }

}

extension HomepageTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.blurView.alpha = min(scrollView.contentOffset.y, 1)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return dataProvider?.newsData.count ?? 0
        return getDataSource().count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension//372
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let dataProvider = dataProvider else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell", for: indexPath) as? NewsTableViewCell
        let dataSource = getDataSource()
        guard dataSource.count > indexPath.row else { return UITableViewCell() }
        let cellDataSource: NewsFeedRow = dataSource[indexPath.row]
        let imageURL = dataProvider.formImageURL(from: cellDataSource.imagePath)
        cell?.delegate = self
        cell?.pictureView.accessibilityIdentifier = "HomeScreenCollectionImageView"
        let url = URL(string: imageURL)
        cell?.pictureView.kf.indicatorType = .activity
        cell?.pictureView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
            switch result {
            case .success(let resData):
                cell?.pictureView.image = resData.image
            case .failure(let error):
                if !error.isNotCurrentTask {
                    guard let defaultImage = UIImage(named: DefaultImageNames.whatsNewPlaceholder) else { return }
                    cell?.pictureView.image = defaultImage
                }
            }
        })
        cell?.titleLabel.text = cellDataSource.headline
        cell?.byLabel.attributedText = getByLineText(byLine: cellDataSource.byLine)
        let newsDate = cellDataSource.postDate
        cell?.dateLabel.text = dataProvider.formatDateString(dateString: newsDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss")
        let bodyText = cellDataSource.newsContent?.first(where: { $0.type == .text })?.body
        let bodyDecoded = dataProvider.formNewsBody(from: bodyText)
        bodyDecoded?.setFontFace(font: UIFont(name: "SFProText-Light", size: 16)!)
        cell?.bodyLabel.attributedText = bodyDecoded
        cell?.fullText = bodyDecoded
        cell?.setCollapse()
        cell?.titleLabel.accessibilityIdentifier = "HomeScreenCollectionTitleLabel"
        cell?.dateLabel.accessibilityIdentifier = "HomeScreenCollectionDateLabel"
        return cell ?? UITableViewCell()
    }
    
    private func getDataSource() -> [NewsFeedRow] {
        switch selectedFilterTab {
        case .all:
            return dataProvider?.allNewsFeedData ?? []
        case .news:
            return dataProvider?.newsFeedData ?? []
        case .specialAlerts:
            return dataProvider?.specialAlertsData ?? []
        }
    }
    
    private func getByLineText(byLine: String?) -> NSAttributedString? {
        let attributedByLine = NSMutableAttributedString(string: "by-line: ", attributes: [.foregroundColor : UIColor(hex: 0x8E8E93)])
        if let font = UIFont(name: "SFProText-Regular", size: 14) {
            attributedByLine.addAttribute(.font, value: font, range: NSMakeRange(0, attributedByLine.length))
        }
        guard let _ = byLine else { return nil }
        attributedByLine.append(NSAttributedString(string: byLine!))
        return attributedByLine
    }
    
}

extension HomepageTableViewController : TappedLabelDelegate {
    func moreButtonDidTapped(in cell: UITableViewCell) {
        guard let cell = cell as? NewsTableViewCell else { return }
        guard let cellIndex = tableView.indexPath(for: cell) else { return }
        let dataSource = getDataSource()
        let newsContent = dataSource[cellIndex.row]
        newsShowDelegate?.showArticleViewController(with: newsContent)
    }
    
    func openUrl(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            displayError(errorMessage: "Something went wrong", title: nil)
        }
    }
}

protocol SelectedOfficeUIUpdateDelegate: AnyObject {
    func updateUIWithNewSelectedOffice()
}
