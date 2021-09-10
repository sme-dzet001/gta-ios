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
    
    var dataSource: [HomepageCellData] = []
    private var lastUpdateDate: Date?
     
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        tableView.accessibilityIdentifier = "HomeScreenTableView"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataLoadingStarted()
        if let dataProvider = dataProvider, !dataProvider.newsDataIsEmpty {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
            tableView.reloadData()
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
    
    private func addBlurToViewIfNeeded() {
        if let gradientMaskLayer = blurView.layer.mask, gradientMaskLayer.name == "grad" {
            return
        }
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.name = "grad"
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientMaskLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        blurView.layer.mask = gradientMaskLayer
    }
    
    private func setUpTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "NewsTableViewCell", bundle: nil), forCellReuseIdentifier: "NewsTableViewCell")
    }
    
    func dataLoadingStarted() {
        guard let dataProvider = dataProvider else { return }
        guard isViewLoaded else { return }
        if dataProvider.newsDataIsEmpty {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
        }
    }
    
    func dataLoadingFinished(errorCode: Int, error: Error?, isFromCache: Bool) {
        guard let dataProvider = dataProvider else { return }
        guard isViewLoaded else { return }
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        if error == nil && errorCode == 200 {
            lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : lastUpdateDate
            errorLabel.isHidden = true
            tableView.reloadData()
        } else {
            let isNoData = dataProvider.newsDataIsEmpty
            if isNoData {
                tableView.reloadData()
            }
            errorLabel.isHidden = !isNoData
            errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
        }
    }
    
    private func loadSpecialAlertsData() {
        let numberOfRows = tableView.numberOfRows(inSection: 1)
        dataProvider?.getSpecialAlertsData { [weak self] (errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    let doubleCheck = numberOfRows == self?.dataProvider?.alertsData.count
                    if let dataHasChanged = self?.tableView.dataHasChanged, dataHasChanged || !doubleCheck {
                        self?.tableView.reloadData()
                    } else {
                        self?.tableView.reloadSections(IndexSet(integersIn: 2...2), with: .none)
                    }
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        }
    }
    
    deinit {
    }

}

extension HomepageTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y > 0 {
            addBlurToViewIfNeeded()
            blurView.isHidden = false
        } else {
            blurView.isHidden = true
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.newsData.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 372
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let dataProvider = dataProvider else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsTableViewCell", for: indexPath) as? NewsTableViewCell
        let cellDataSource = dataProvider.newsData[indexPath.row]
        let imageURL = dataProvider.formImageURL(from: cellDataSource.posterUrl)
        cell?.pictureView.accessibilityIdentifier = "HomeScreenCollectionImageView"
        let url = URL(string: imageURL)
        cell?.pictureView.kf.indicatorType = .activity
        cell?.pictureView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
            switch result {
            case .success(let resData):
                cell?.pictureView.image = resData.image
            case .failure(let error):
                if !error.isNotCurrentTask {
                    cell?.pictureView.image = nil
                }
            }
        })
        cell?.titleLabel.text = cellDataSource.newsTitle
        cell?.byLabel.text = cellDataSource.newsAuthor
        let newsDate = cellDataSource.newsDate
        cell?.dateLabel.text = dataProvider.formatDateString(dateString: newsDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss")
        cell?.titleLabel.accessibilityIdentifier = "HomeScreenCollectionTitleLabel"
        cell?.dateLabel.accessibilityIdentifier = "HomeScreenCollectionDateLabel"
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataProvider = dataProvider, dataProvider.newsData.count > indexPath.row else { return }
        let newsBody = dataProvider.newsData[indexPath.row].newsBody
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        newsShowDelegate?.showArticleViewController(with: newsBody)
    }
    
}

/*extension HomepageTableViewController: OfficeSelectionDelegate, SelectedOfficeUIUpdateDelegate {
    func officeWasSelected() {
        officeLoadingIsEnabled = false
        updateUIWithSelectedOffice()
        dataProvider?.getCurrentOffice(completion: { [weak self] (_, _, _) in
            self?.officeLoadingIsEnabled = true
        })
    }
    
    func updateUIWithNewSelectedOffice() {
        DispatchQueue.main.async {
            self.officeLoadingIsEnabled = true
            self.loadOfficesData()
        }
    }
    
    private func updateUIWithSelectedOffice() {
        DispatchQueue.main.async {
            self.officeLoadingError = nil
            if self.tableView.dataHasChanged {
                self.tableView.reloadData()
            } else {
                UIView.performWithoutAnimation {
                    self.tableView.reloadSections(IndexSet(integersIn: 4...4), with: .none)
                }
            }
        }
    }
}*/

struct HomepageCellData {
    var mainText: String?
    var additionalText: String? = nil
    var image: String? = nil
    var infoType: infoType = .info
    
    var enabled: Bool {
        return infoType != .returnToWork
    }
}

enum infoType {
    case office
    case info
    case deskFinder
    case returnToWork
}

protocol SelectedOfficeUIUpdateDelegate: AnyObject {
    func updateUIWithNewSelectedOffice()
}
