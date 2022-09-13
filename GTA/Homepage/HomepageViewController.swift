//
//  HomepageViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit
import AdvancedPageControl
import PanModal
import Parchment

enum FilterTabType : String {
    case all = "All"
    case news = "News"
    case specialAlerts = "Special Alerts"
    //case teamsNews = "Teams News"
}

class HomepageViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var emergencyOutageBannerView: GlobalAlertBannerView!
    @IBOutlet weak var globalProductionAlertBannerView: GlobalAlertBannerView!
    @IBOutlet weak var emergencyOutageBannerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var globalProductionAlertBannerViewHeight: NSLayoutConstraint!
    
    weak var badgeDelegate: AlertBadgeDelegate?
    private var newsTabs: [HomepageTableViewController] = []
    
    private var dataProvider: HomeDataProvider = HomeDataProvider()
    private var lastUpdateDate: Date?
    
    private var presentedVC: ArticleViewController?
    
    private var filterTabTypes : [FilterTabType] = [.all, .news, .specialAlerts]
    
    private var filterTabItemWidths : [CGFloat] {
        var result: [CGFloat] = []
        guard let font: UIFont = UIFont(name: "SFProText-Medium", size: 14) else { return result }
        for filterTabType in filterTabTypes {
            let itemWidth = filterTabType.rawValue.width(height: 40, font: font) + 50
            result.append(itemWidth)
        }
        let sumWidth = result.reduce(0, +)
        let extraWidth = (view.bounds.size.width - 48 - sumWidth) / CGFloat(filterTabTypes.count)
        if extraWidth > 0 {
            result = result.map({ return $0 + extraWidth })
        }
        return result
    }
    
    private var isEmergencyOutageBannerVisible: Bool {
        let alert = dataProvider.globalAlertsData
        if alert == nil || (alert?.isExpired ?? true) || alert?.status == .open {
            return false
        }
        return true
    }
    
    private var isGlobalProductionAlertBannerVisible: Bool {
        let alert = dataProvider.productionGlobalAlertsData
        if alert == nil || (alert?.isExpired ?? true) || alert?.status == .open || dismissDidPressed {
            return false
        }
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    private var dismissDidPressed: Bool {
        if let value = UserDefaults.standard.value(forKey: "ClosedProdAlert") as? [String : String?] {
            let issueReason = value["issueReason"] == self.dataProvider.productionGlobalAlertsData?.issueReason
            let prodAlertsStatus = value["prodAlertsStatus"] == self.dataProvider.productionGlobalAlertsData?.prodAlertsStatus.rawValue
            let summary = value["summary"] == self.dataProvider.productionGlobalAlertsData?.summary
            return issueReason && prodAlertsStatus && summary
        }
        return false
    }
    
    private var emergencyOutageLoaded: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if self?.navigationController?.topViewController is HomepageViewController, let emergencyLoaded = self?.emergencyOutageLoaded, emergencyLoaded {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
        }
    }
    
    private var hasActiveGlobalProdAlerts: Bool {
        guard let data = dataProvider.productionGlobalAlertsData else { return false }
        guard data.prodAlertsStatus == .activeAlert || data.prodAlertsStatus == .closed else { return false }
        let eventStarted = data.startDate.timeIntervalSince1970 >= Date().timeIntervalSince1970
        let eventFinished = data.closeDate.timeIntervalSince1970 + 3600 > Date().timeIntervalSince1970
        return eventStarted || eventFinished
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(emergencyOutageNotificationReceived), name: Notification.Name(NotificationsNames.emergencyOutageNotificationReceived), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(globalProductionAlertNotificationReceived), name: Notification.Name(NotificationsNames.globalProductionAlertNotificationReceived), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getProductionAlertsCount), name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBannerViews()
        setNeedsStatusBarAppearanceUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(getGlobalAlertsIgnoringCache), name: Notification.Name(NotificationsNames.emergencyOutageNotificationDisplayed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getGlobalProductionAlertsIgnoringCache), name: Notification.Name(NotificationsNames.globalProductionAlertNotificationDisplayed), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barStyle = .default
        loadNewsData()
        if UserDefaults.standard.bool(forKey: "emergencyOutageNotificationReceived") {
            emergencyOutageNotificationReceived()
        }
        if let productionAlertInfo = UserDefaults.standard.object(forKey: "globalProductionAlertNotificationReceived") as? [String : Any] {
            navigateToGlobalProdAlert(withAlertInfo: productionAlertInfo)
        }
        updateBannerViews()
        getAllAlertsWithCache()
        getProductionAlertsCount()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.emergencyOutageNotificationReceived), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalProductionAlertNotificationReceived), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.emergencyOutageNotificationDisplayed), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalProductionAlertNotificationDisplayed), object: nil)
    }
    
    private func setUpBannerViews() {
        emergencyOutageBannerView.delegate = self
        globalProductionAlertBannerView.delegate = self
    }

    private func updateBannerViews() {
        if isEmergencyOutageBannerVisible {
            emergencyOutageBannerView?.isHidden = false
            emergencyOutageBannerViewHeight?.constant = 72
            populateEmergencyOutageBanner()
        } else {
            emergencyOutageBannerView?.isHidden = true
            emergencyOutageBannerViewHeight?.constant = 0
        }
        
        if isGlobalProductionAlertBannerVisible {
            globalProductionAlertBannerView?.isHidden = false
            globalProductionAlertBannerViewHeight?.constant = 72
            populateGlobalProductionAlertBanner()
        } else {
            globalProductionAlertBannerView?.isHidden = true
            globalProductionAlertBannerViewHeight?.constant = 0
        }
    }
    
    private func populateEmergencyOutageBanner() {
        guard let alert = dataProvider.globalAlertsData else { return }
        emergencyOutageBannerView?.alertLabel.text = "Emergency Outage: \(alert.alertTitle ?? "")"
        if alert.status == .closed {
            emergencyOutageBannerView?.setAlertOff()
        } else {
            emergencyOutageBannerView?.setAlertOn()
        }
    }
    
    private func populateGlobalProductionAlertBanner() {
        guard let alert = dataProvider.productionGlobalAlertsData else { return }
        guard !alert.isExpired else { return }
        globalProductionAlertBannerView?.alertLabel.text = "Production Alert: \(alert.summary ?? "")"
        globalProductionAlertBannerView?.closeButton.isHidden = false
        globalProductionAlertBannerView?.delegate = self
        globalProductionAlertBannerView?.setAlertBannerForGlobalProdAlert(prodAlertsStatus: alert.prodAlertsStatus)
    }
    
    @IBAction func emergencyOutageBannerPressed(_ sender: Any) {
        showGlobalAlertModal(isProdAlert: false, productionAlertId: nil)
    }
    
    @IBAction func globalProductionAlertBannerPressed(_ sender: Any) {
        showGlobalAlertModal(isProdAlert: true, productionAlertId: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTable" {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Home", bundle: nil)
            if let allNewsViewController = storyBoard.instantiateViewController(withIdentifier: "HomepageTableViewController") as? HomepageTableViewController, let promotedNewsViewController = storyBoard.instantiateViewController(withIdentifier: "HomepageTableViewController") as? HomepageTableViewController, let specialAlertsViewController = storyBoard.instantiateViewController(withIdentifier: "HomepageTableViewController") as? HomepageTableViewController {//}, let applicationNewsViewController = storyBoard.instantiateViewController(withIdentifier: "HomepageTableViewController") as? HomepageTableViewController {
                promotedNewsViewController.selectedFilterTab = .news
                specialAlertsViewController.selectedFilterTab = .specialAlerts
                newsTabs = [allNewsViewController, promotedNewsViewController, specialAlertsViewController]//, applicationNewsViewController]
            }
            
            for newsTab in newsTabs {
                newsTab.loadViewIfNeeded()
                newsTab.dataProvider = dataProvider
                newsTab.newsShowDelegate = self
            }
            
            let pagingVC = segue.destination as? PagingViewController
            pagingVC?.dataSource = self
            pagingVC?.delegate = self
            pagingVC?.register(PagingTitleCell.self, for: PagingIndexItem.self)
            pagingVC?.indicatorColor = UIColor(hex: 0xCC0000)
            pagingVC?.selectedTextColor = .black
            pagingVC?.borderOptions = .hidden
            pagingVC?.indicatorOptions = .visible(height: 2, zIndex: Int.max, spacing: .zero, insets: .zero)
            if let filterTabFont = UIFont(name: "SFProText-Medium", size: 14) {
                pagingVC?.font = filterTabFont
                pagingVC?.selectedFont = filterTabFont
            }
            pagingVC?.menuItemSize = .selfSizing(estimatedWidth: 80, height: 40)
            //pagingVC?.menuInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
            pagingVC?.menuItemLabelSpacing = 15
            pagingVC?.menuHorizontalAlignment = .center
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
    }
    
    private func loadNewsData() {
        guard lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() else { return }
        guard !dataProvider.getNewsFeedInProgress else { return }
        dataProvider.getNewsFeedData { [weak self] (isFromCache, dataWasChanged, errorCode, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error == nil && errorCode == 200 {
                    self.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self.lastUpdateDate
                }
                for newsTab in self.newsTabs {
                    newsTab.dataLoadingFinished(dataWasChanged: dataWasChanged, errorCode: errorCode, error: error, isFromCache: isFromCache)
                }
            }
        }
    }
    
    @objc private func getAllAlertsWithCache() {
        getGlobalAlerts()
        getGlobalProductionAlerts()
    }
    
    @objc private func getAllAlertsIgnoringCache() {
        getGlobalAlertsIgnoringCache()
        getGlobalProductionAlertsIgnoringCache()
    }
    
    @objc private func getGlobalAlerts() {
        dataProvider.getGlobalAlerts(completion: {[weak self] isFromCache, dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if error == nil && errorCode == 200 {
                    self?.emergencyOutageLoaded = dataWasChanged && !isFromCache
                    self?.updateBannerViews()
                    if let data = self?.dataProvider.globalAlertsData {
                        switch data.status {
                        case .inProgress:
                            self?.badgeDelegate?.globalAlertsBadges = 1
                            self?.tabBarController?.addAlertItemBadge(atIndex: 0)
                        default:
                            if let self = self, !self.hasActiveGlobalProdAlerts {
                                self.badgeDelegate?.globalAlertsBadges = 0
                                self.tabBarController?.removeItemBadge(atIndex: 0)
                            }
                        }
                    }
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        })
    }
    
    @objc private func getGlobalAlertsIgnoringCache() {
        dataProvider.getGlobalAlertsIgnoringCache {[weak self] _, dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.emergencyOutageLoaded = true
                    self?.updateBannerViews()
                }
            }
        }
    }
    
    @objc private func getGlobalProductionAlertsIgnoringCache() {
        dataProvider.getGlobalProductionIgnoringCache {[weak self] dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if dataWasChanged, error == nil {
                    self?.updateBannerViews()
                }
            }
        }
    }
    
    private func getGlobalProductionAlerts() {
        dataProvider.getGlobalProductionAlerts(completion: {[weak self] dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if error == nil && errorCode == 200 {
                    self?.updateBannerViews()
                    if let data = self?.dataProvider.productionGlobalAlertsData {
                        switch data.prodAlertsStatus {
                        case .newAlertCreated, .reminderState:
                            if self?.dataProvider.globalAlertsData?.status != .inProgress {
                                self?.tabBarController?.removeItemBadge(atIndex: 0)
                            }
                        case .activeAlert, .closed:
                            let eventStarted = data.startDate.timeIntervalSince1970 >= Date().timeIntervalSince1970
                            let eventFinished = data.closeDate.timeIntervalSince1970 + 3600 > Date().timeIntervalSince1970
                            if eventStarted || eventFinished {
                                self?.tabBarController?.addAlertItemBadge(atIndex: 0)
                                //guard let mainVC = self?.tabBarController?.navigationController?.viewControllers.first(where: { $0 is MainViewController}) as? MainViewController else {return}
                                self?.badgeDelegate?.globalAlertsBadges = 1
                            }
                        default:
                            return
                        }
                    }
                } else {
                    //self?.displayError(errorMessage: "Error was happened!")
                }
            }
        })
    }
    
    @objc func globalProductionAlertNotificationReceived(notification: NSNotification) {
        guard let productionAlertInfo = notification.userInfo as? [String : Any] else { return }
        navigateToGlobalProdAlert(withAlertInfo: productionAlertInfo)
    }
    
    private func navigateToGlobalProdAlert(withAlertInfo productionAlertInfo: [String : Any]) {
        if let _ = UserDefaults.standard.object(forKey: "globalProductionAlertNotificationReceived") as? [String : Any] {
            UserDefaults.standard.removeObject(forKey: "globalProductionAlertNotificationReceived")
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        guard let embeddedController = self.navigationController else { return }
        guard let homepageTabIdx = self.tabBarController?.viewControllers?.firstIndex(of: embeddedController) else { return }
        guard let productionAlertId = productionAlertInfo["production_alert_id"] as? String else { return }
        UIApplication.shared.applicationIconBadgeNumber = 0
        appDelegate.dismissPanModalIfPresented { [weak self] in
            guard let self = self else { return }
            self.tabBarController?.selectedIndex = homepageTabIdx
            embeddedController.popToRootViewController(animated: false)
            NotificationCenter.default.post(name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
            self.tabBarController?.selectedIndex = homepageTabIdx
            embeddedController.popToRootViewController(animated: false)
            self.dataProvider.forceUpdateAlertDetails = true
            self.showGlobalAlertModal(isProdAlert: true, productionAlertId: productionAlertId)
        }
    }
    
    @objc func emergencyOutageNotificationReceived() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.dismissPanModalIfPresented { [weak self] in
            guard let self = self else { return }
            guard let embeddedController = self.navigationController else { return }
            guard let homepageTabIdx = self.tabBarController?.viewControllers?.firstIndex(of: embeddedController) else { return }
            self.tabBarController?.selectedIndex = homepageTabIdx
            embeddedController.popToRootViewController(animated: false)
            if UserDefaults.standard.bool(forKey: "emergencyOutageNotificationReceived") {
                UserDefaults.standard.removeObject(forKey: "emergencyOutageNotificationReceived")
                //if let alert = self.dataProvider.globalAlertsData, !alert.isExpired {
                NotificationCenter.default.post(name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
                self.dataProvider.forceUpdateAlertDetails = true
                self.showGlobalAlertModal(isProdAlert: false)
                //}
            } else {
                NotificationCenter.default.post(name: Notification.Name(NotificationsNames.globalAlertWillShow), object: nil)
                self.tabBarController?.selectedIndex = homepageTabIdx
                embeddedController.popToRootViewController(animated: false)
                self.dataProvider.forceUpdateAlertDetails = true
                self.showGlobalAlertModal(isProdAlert: false)
            }
        }
    }
    
    @objc private func didBecomeActive() {
        if UserDefaults.standard.bool(forKey: "emergencyOutageNotificationReceived") {
            emergencyOutageNotificationReceived()
        }
        if let productionAlertInfo = UserDefaults.standard.object(forKey: "globalProductionAlertNotificationReceived") as? [String : Any] {
            navigateToGlobalProdAlert(withAlertInfo: productionAlertInfo)
        }
        getAllAlertsIgnoringCache()
        getProductionAlertsCount()
    }
    
    @objc private func getProductionAlertsCount() {
        dataProvider.getProductionAlerts {[weak self] _, _, count in
            DispatchQueue.main.async {
                self?.tabBarController?.addProductionAlertsItemBadge(atIndex: 2, value: count > 0 ? "\(count)" : nil)
                //guard let mainVC = self?.tabBarController?.navigationController?.viewControllers.first(where: { $0 is MainViewController}) as? MainViewController else {return}
                self?.badgeDelegate?.productionAlertBadges = count
            }
        }
    }
    
    func showGlobalAlertModal(isProdAlert: Bool, productionAlertId: String? = nil) {
        let globalAlertViewController = GlobalAlertViewController()
        globalAlertViewController.dataProvider = dataProvider
        globalAlertViewController.isProdAlert = isProdAlert
        globalAlertViewController.productionAlertId = productionAlertId
        presentPanModal(globalAlertViewController)
        
    }
}

extension HomepageViewController: PagingViewControllerDataSource, PagingViewControllerDelegate {
    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return newsTabs.count
    }
    
    func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return newsTabs[index]
    }
    
    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        return PagingIndexItem(index: index, title: filterTabTypes[index].rawValue)
    }
    
    func pagingViewController(_ pagingViewController: PagingViewController, didSelectItem pagingItem: PagingItem) {
        loadNewsData()
    }
    
    
}

extension HomepageViewController: DismissAlertDelegate {
    func closeAlertDidPressed() {
        let alert = UIAlertController(title: "Confirm closing", message: "Notification will appear again when the outage starts", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let prodGlobalAlertsData = self.dataProvider.productionGlobalAlertsData
            let closedData = ["issueReason" : prodGlobalAlertsData?.issueReason, "prodAlertsStatus" : prodGlobalAlertsData?.prodAlertsStatus.rawValue, "summary" : prodGlobalAlertsData?.summary]
            UserDefaults.standard.setValue(closedData, forKey: "ClosedProdAlert")
            self.updateBannerViews()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension HomepageViewController: NewsShowDelegate {
    func showArticleViewController(with content: NewsFeedRow) {
        let newsViewController = NewsScreenViewController(nibName: "NewsScreenViewController", bundle: nil)
        newsViewController.newsData = content
        navigationController?.pushViewController(newsViewController, animated: true)
    }
}

protocol NewsShowDelegate: AnyObject {
    func showArticleViewController(with content: NewsFeedRow)
}

protocol PanModalAppearanceDelegate: AnyObject {
    func needScrollToDirection(_ direction: UICollectionView.ScrollPosition)
    func panModalDidDismiss()
}
