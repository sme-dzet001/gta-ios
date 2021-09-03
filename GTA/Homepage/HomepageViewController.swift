//
//  HomepageViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit
import AdvancedPageControl
import PanModal

enum FilterTabType : String {
    case all = "All"
    case news = "News"
    case specialAlerts = "Special Alerts"
    case teamsNews = "Teams News"
}

class HomepageViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var filterTabs: UICollectionView!
    @IBOutlet weak var emergencyOutageBannerView: GlobalAlertBannerView!
    @IBOutlet weak var globalProductionAlertBannerView: GlobalAlertBannerView!
    @IBOutlet weak var emergencyOutageBannerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var globalProductionAlertBannerViewHeight: NSLayoutConstraint!
    
    private var dataProvider: HomeDataProvider = HomeDataProvider()
    private var lastUpdateDate: Date?
    
    //var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var homepageTableVC: HomepageTableViewController?
    
    private var presentedVC: ArticleViewController?
    
    private var filterTabTypes : [FilterTabType] = [.all, .news, .specialAlerts, .teamsNews]
    
    private var selectedFilterTab: FilterTabType = .all
    
    @objc private func onSwipe(_ gesture: UISwipeGestureRecognizer) {
        var selectedFilterTabIdx = filterTabTypes.firstIndex(of: selectedFilterTab) ?? 0
        if gesture.direction == .right && selectedFilterTabIdx > 0 {
            selectedFilterTabIdx -= 1
        }
        if gesture.direction == .left && selectedFilterTabIdx < (filterTabTypes.count - 1) {
            selectedFilterTabIdx += 1
        }
        filterTabs.selectItem(at: IndexPath(item: selectedFilterTabIdx, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        selectedFilterTab = filterTabTypes[selectedFilterTabIdx]
    }
    
    private var filterTabItemWidths : [CGFloat] {
        var result: [CGFloat] = []
        guard let font: UIFont = UIFont(name: "SFProText-Medium", size: 14) else { return result }
        for filterTabType in filterTabTypes {
            let itemWidth = filterTabType.rawValue.width(height: self.filterTabs.frame.height, font: font) + 50
            result.append(itemWidth)
        }
        let sumWidth = result.reduce(0, +)
        let extraWidth = (view.bounds.size.width - 48 - sumWidth) / CGFloat(filterTabTypes.count)
        if extraWidth > 0 {
            result = result.map({ return $0 + extraWidth })
        }
        return result
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
        setUpFilterTabs()
        setUpBannerViews()
        setNeedsStatusBarAppearanceUpdate()
        
        let swipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        swipeGestureLeft.direction = [.left]
        view.addGestureRecognizer(swipeGestureLeft)
        
        let swipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        swipeGestureRight.direction = [.right]
        view.addGestureRecognizer(swipeGestureRight)
        
        NotificationCenter.default.addObserver(self, selector: #selector(getAllAlerts), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getGlobalAlertsIgnoringCache), name: Notification.Name(NotificationsNames.emergencyOutageNotificationDisplayed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getGlobalProductionAlertsIgnoringCache), name: Notification.Name(NotificationsNames.globalProductionAlertNotificationDisplayed), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.bool(forKey: "emergencyOutageNotificationReceived") {
            emergencyOutageNotificationReceived()
        }
        if let productionAlertInfo = UserDefaults.standard.object(forKey: "globalProductionAlertNotificationReceived") as? [String : Any] {
            navigateToGlobalProdAlert(withAlertInfo: productionAlertInfo)
        }
        updateBannerViews()
        getAllAlerts()
        getProductionAlertsCount()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.emergencyOutageNotificationReceived), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.productionAlertNotificationDisplayed), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalProductionAlertNotificationReceived), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.emergencyOutageNotificationDisplayed), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.globalProductionAlertNotificationDisplayed), object: nil)
    }
    
    private func setUpFilterTabs() {
        filterTabs.dataSource = self
        filterTabs.delegate = self
        if let layout = filterTabs.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        filterTabs.register(UINib(nibName: "HomepageFilterTabsCollectionCell", bundle: nil), forCellWithReuseIdentifier: "HomepageFilterTabsCollectionCell")
        
        filterTabs.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
    }
    
    private func setUpBannerViews() {
        emergencyOutageBannerView.delegate = self
        globalProductionAlertBannerView.delegate = self
    }

    private func updateBannerViews() {
        if isEmergencyOutageBannerVisible {
            emergencyOutageBannerView.isHidden = false
            emergencyOutageBannerViewHeight.constant = 80
            populateEmergencyOutageBanner()
        } else {
            emergencyOutageBannerView.isHidden = true
            emergencyOutageBannerViewHeight.constant = 0
        }
        
        if isGlobalProductionAlertBannerVisible {
            globalProductionAlertBannerView.isHidden = false
            globalProductionAlertBannerViewHeight.constant = 80
            populateGlobalProductionAlertBanner()
        } else {
            globalProductionAlertBannerView.isHidden = true
            globalProductionAlertBannerViewHeight.constant = 0
        }
    }
    
    private func populateEmergencyOutageBanner() {
        guard let alert = dataProvider.globalAlertsData else { return }
        emergencyOutageBannerView.alertLabel.text = "Emergency Outage: \(alert.alertTitle ?? "")"
        if alert.status == .closed {
            emergencyOutageBannerView.setAlertOff()
        } else {
            emergencyOutageBannerView.setAlertOn()
        }
    }
    
    private func populateGlobalProductionAlertBanner() {
        guard let alert = dataProvider.productionGlobalAlertsData else { return }
        guard !alert.isExpired else { return }
        globalProductionAlertBannerView.alertLabel.text = "Production Alert: \(alert.summary ?? "")"
        globalProductionAlertBannerView.closeButton.isHidden = false
        globalProductionAlertBannerView.delegate = self
        globalProductionAlertBannerView.setAlertBannerForGlobalProdAlert(prodAlertsStatus: alert.prodAlertsStatus)
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
        return .lightContent
    }
    
    @IBAction func emergencyOutageBannerPressed(_ sender: Any) {
        showGlobalAlertModal(isProdAlert: false, productionAlertId: nil)
    }
    
    @IBAction func globalProductionAlertBannerPressed(_ sender: Any) {
        showGlobalAlertModal(isProdAlert: true, productionAlertId: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTable" {
            homepageTableVC = segue.destination as? HomepageTableViewController
            homepageTableVC?.dataProvider = dataProvider
            homepageTableVC?.newsShowDelegate = self
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
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
            DispatchQueue.main.async {
                if self.navigationController?.topViewController is HomepageViewController, self.emergencyOutageLoaded {
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
    
    @objc private func getAllAlerts() {
        getGlobalAlerts()
        getGlobalProductionAlerts()
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
                            self?.tabBarController?.addAlertItemBadge(atIndex: 0)
                        default:
                            if let self = self, !self.hasActiveGlobalProdAlerts {
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
                if dataWasChanged, error == nil {
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
        getProductionAlertsCount()
    }
    
    @objc private func getProductionAlertsCount() {
        dataProvider.getProductionAlerts {[weak self] _, _, count in
            DispatchQueue.main.async {
                self?.tabBarController?.addProductionAlertsItemBadge(atIndex: 2, value: count > 0 ? "\(count)" : nil)
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

extension HomepageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterTabTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomepageFilterTabsCollectionCell", for: indexPath) as? HomepageFilterTabsCollectionCell {
            cell.titleLabel.text = filterTabTypes[indexPath.item].rawValue
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        filterTabs.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        selectedFilterTab = filterTabTypes[indexPath.item]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = filterTabItemWidths[indexPath.item]
        return CGSize(width: itemWidth, height: self.filterTabs.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension HomepageViewController: NewsShowDelegate {
    func showArticleViewController(with text: String?) {
        let articleViewController = ArticleViewController()
        presentedVC = articleViewController
        let htmlBody = dataProvider.formNewsBody(from: text)
        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
            htmlBody?.setFontFace(font: neededFont)
        }
        if let _ = htmlBody {
            articleViewController.attributedArticleText = htmlBody
        } else {
            articleViewController.articleText = text
        }
        presentPanModal(articleViewController)
    }
}
/*
extension HomepageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider.newsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard dataProvider.newsData.count > indexPath.row else { return UICollectionViewCell() }
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCollectionViewCell", for: indexPath) as? NewsCollectionViewCell {
            let cellDataSource = dataProvider.newsData[indexPath.row]
            let imageURL = dataProvider.formImageURL(from: cellDataSource.posterUrl)
            cell.imageView.accessibilityIdentifier = "HomeScreenCollectionImageView"
            let url = URL(string: imageURL)
            cell.imageView.kf.indicatorType = .activity
            cell.imageView.kf.setImage(with: url, placeholder: nil, options: nil, completionHandler: { (result) in
                switch result {
                case .success(let resData):
                    cell.imageView.image = resData.image
                case .failure(let error):
                    if !error.isNotCurrentTask {
                        cell.imageView.image = nil
                    }
                }
            })
            //cell.titleLabel.text = cellDataSource.newsTitle
            //cell.byLabel.text = cellDataSource.newsAuthor
            let newsDate = cellDataSource.newsDate
            //cell.dateLabel.text = dataProvider.formatDateString(dateString: newsDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss")
            cell.titleLabel.attributedText = addShadow(for: cellDataSource.newsTitle)
            cell.titleLabel.accessibilityIdentifier = "HomeScreenCollectionTitleLabel"
            cell.byLabel.attributedText = addShadow(for: cellDataSource.newsAuthor)
            cell.byLabel.accessibilityIdentifier = "HomeScreenCollectionByLabel"
            cell.dateLabel.attributedText = addShadow(for: newsDate?.getFormattedDateStringForMyTickets())
            cell.dateLabel.accessibilityIdentifier = "HomeScreenCollectionDateLabel"
            //cell.dateLabel.attributedText = addShadow(for: dataProvider.formatDateString(dateString: newsDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss"))
            cell.configurePosition()
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard dataProvider.newsData.count > indexPath.row else { return }
        let newsBody = dataProvider.newsData[indexPath.row].newsBody
        showArticleViewController(with: newsBody)
        selectedIndexPath.row = indexPath.row
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSet = scrollView.contentOffset.x
        let width = scrollView.frame.width
        pageControl.setPageOffset(CGFloat(offSet) / CGFloat(width))
    }
    
}
*/

/*extension HomepageViewController: PanModalAppearanceDelegate {
    
    func needScrollToDirection(_ scrollPosition: UICollectionView.ScrollPosition) {
        if scrollPosition == .left && selectedIndexPath.row < dataProvider.newsData.count - 1 {
            selectedIndexPath.row += 1
        } else if scrollPosition == .right && selectedIndexPath.row > 0 {
            selectedIndexPath.row -= 1
        } else {
            return
        }
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.selectItem(at: selectedIndexPath, animated: true, scrollPosition: scrollPosition)
        let newsBody = dataProvider.newsData[selectedIndexPath.row].newsBody
        let htmlBody = dataProvider.formNewsBody(from: newsBody)
        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
            htmlBody?.setFontFace(font: neededFont)
        }
        self.presentedVC?.attributedArticleText = htmlBody
    }
    
    func panModalDidDismiss() {
        //pageControl.isHidden = false
    }
}*/

protocol NewsShowDelegate: AnyObject {
    func showArticleViewController(with text: String?)
}

protocol PanModalAppearanceDelegate: AnyObject {
    func needScrollToDirection(_ direction: UICollectionView.ScrollPosition)
    func panModalDidDismiss()
}
