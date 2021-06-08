//
//  HomepageViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit
import AdvancedPageControl
import PanModal

class HomepageViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var pageControl: AdvancedPageControlView!
    
    private var dataProvider: HomeDataProvider = HomeDataProvider()
    private var lastUpdateDate: Date?
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var homepageTableVC: HomepageTableViewController?
    
    private var presentedVC: ArticleViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        setUpPageControl()
        setNeedsStatusBarAppearanceUpdate()
        
        NotificationCenter.default.addObserver(self, selector: #selector(emergencyOutageNotificationReceived), name: Notification.Name(NotificationsNames.emergencyOutageNotificationReceived), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastUpdateDate == nil || Date() >= lastUpdateDate ?? Date() {
            loadNewsData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(NotificationsNames.emergencyOutageNotificationReceived), object: nil)
    }
    
    private func loadNewsData() {
        if dataProvider.newsDataIsEmpty {
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
            pageControl.isHidden = true
        }
        dataProvider.getGlobalNewsData { [weak self] (errorCode, error, isFromCache) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.lastUpdateDate = !isFromCache ? Date().addingTimeInterval(60) : self?.lastUpdateDate
                    self?.errorLabel.isHidden = true
                    self?.pageControl.isHidden = self?.dataProvider.newsDataIsEmpty ?? true
                    self?.pageControl.numberOfPages = self?.dataProvider.newsData.count ?? 0
                    self?.collectionView.reloadData()
                    if UserDefaults.standard.bool(forKey: "emergencyOutageNotificationReceived") {
                        self?.emergencyOutageNotificationReceived()
                    }
                } else {
                    let isNoData = (self?.dataProvider.newsDataIsEmpty ?? true)
                    if isNoData {
                        self?.collectionView.reloadData()
                    }
                    self?.pageControl.isHidden = isNoData
                    self?.errorLabel.isHidden = !isNoData
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        }
    }
    
    private func setUpPageControl() {
        let inactiveColor = UIColor(red: 147.0 / 255.0, green: 130.0 / 255.0, blue: 134.0 / 255.0, alpha: 1.0)
        let newsCount = dataProvider.newsData.count
        pageControl.drawer = ExtendedDotDrawer(numberOfPages: newsCount,  height: 4, width: 6, space: 6, dotsColor: inactiveColor, borderColor: inactiveColor, indicatorBorderColor: .white)
        pageControl.drawer.currentItem = 0
    }
    
    private func setUpCollectionView() {
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView?.collectionViewLayout as? AnimatedCollectionViewLayout {
            layout.scrollDirection = .horizontal
        }
        collectionView.register(UINib(nibName: "NewsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "NewsCollectionViewCell")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTable" {
            homepageTableVC = segue.destination as? HomepageTableViewController
            homepageTableVC?.dataProvider = dataProvider
            homepageTableVC?.showModalDelegate = self
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
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
                if let alert = self.dataProvider.globalAlertsData, !alert.isExpired {
                    self.showGlobalAlertModal()
                }
            } else {
                self.dataProvider.getGlobalAlertsIgnoringCache(completion: {[weak self] dataWasChanged, errorCode, error in
                    DispatchQueue.main.async {
                        if let alert = self?.dataProvider.globalAlertsData, !alert.isExpired {
                            self?.tabBarController?.selectedIndex = homepageTabIdx
                            embeddedController.popToRootViewController(animated: false)
                            self?.showGlobalAlertModal()
                        }
                    }
                })
            }
        }
    }
    
}

extension HomepageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider.newsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard dataProvider.newsData.count > indexPath.row else { return UICollectionViewCell() }
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCollectionViewCell", for: indexPath) as? NewsCollectionViewCell {
            let cellDataSource = dataProvider.newsData[indexPath.row]
            let imageURL = dataProvider.formImageURL(from: cellDataSource.posterUrl)
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
            cell.byLabel.attributedText = addShadow(for: cellDataSource.newsAuthor)
            cell.dateLabel.attributedText = addShadow(for: newsDate?.getFormattedDateStringForMyTickets())
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
    
    private func showArticleViewController(with text: String?) {
        let articleViewController = ArticleViewController()
        presentedVC = articleViewController
        articleViewController.appearanceDelegate = self
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSet = scrollView.contentOffset.x
        let width = scrollView.frame.width
        pageControl.setCurrentItem(offset: CGFloat(offSet),width: CGFloat(width))
    }
    
}

extension HomepageViewController: PanModalAppearanceDelegate {
    
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
    
    func panModalDidDissmiss() {
        //pageControl.isHidden = false
    }
}

extension HomepageViewController: ShowGlobalAlertModalDelegate {
    func showGlobalAlertModal() {
        let globalAlertViewController = GlobalAlertViewController()
        globalAlertViewController.dataProvider = dataProvider
        presentPanModal(globalAlertViewController)
        
    }
}

protocol PanModalAppearanceDelegate: AnyObject {
    func needScrollToDirection(_ direction: UICollectionView.ScrollPosition)
    func panModalDidDissmiss()
}

protocol ShowGlobalAlertModalDelegate: AnyObject {
    func showGlobalAlertModal()
}
