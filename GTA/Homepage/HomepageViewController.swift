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
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var homepageTableVC: HomepageTableViewController?
    
    private var presentedVC: ArticleViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        setUpPageControl()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNewsData()
    }
    
    private func loadNewsData() {
        if dataProvider.newsDataIsEmpty {
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
            pageControl.isHidden = true
        }
        dataProvider.getGlobalNewsData { [weak self] (errorCode, error) in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error == nil && errorCode == 200 {
                    self?.errorLabel.isHidden = true
                    self?.pageControl.isHidden = self?.dataProvider.newsDataIsEmpty ?? true
                    self?.pageControl.numberOfPages = self?.dataProvider.newsData.count ?? 0
                    self?.collectionView.reloadData()
                } else {
                    self?.errorLabel.isHidden = !(self?.dataProvider.newsDataIsEmpty ?? true)
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
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
    }
    
}

extension HomepageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider.newsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCollectionViewCell", for: indexPath) as? NewsCollectionViewCell {
            let cellDataSource = dataProvider.newsData[indexPath.row]
            let imageURL = dataProvider.formImageURL(from: cellDataSource.posterUrl)
            if let url = URL(string: imageURL) {
                cell.imageUrl = imageURL
                dataProvider.getPosterImageData(from: url) { (data, error) in
                    if cell.imageUrl != imageURL { return }
                    if let imageData = data, error == nil {
                        let image = UIImage(data: imageData)
                        cell.imageView.image = image
                    }
                }
            }
            cell.titleLabel.text = cellDataSource.newsTitle
            let newsDate = cellDataSource.newsDate
            cell.dateLabel.text = dataProvider.formatDateString(dateString: newsDate, initialDateFormat: "yyyy-MM-dd'T'HH:mm:ss")
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let articleViewController = ArticleViewController()
        articleViewController.appearanceDelegate = self
        var statusBarHeight: CGFloat = 0.0
        if #available(iOS 13.0, *) {
            statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            statusBarHeight = view.window?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight : statusBarHeight - 10
        } else {
            statusBarHeight = self.containerView.bounds.height - UIApplication.shared.statusBarFrame.height
            statusBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? statusBarHeight : statusBarHeight - 10
        }
        articleViewController.initialHeight = self.containerView.bounds.height - statusBarHeight
        let newsBody = dataProvider.newsData[indexPath.row].newsBody
        let htmlBody = dataProvider.formNewsBody(from: newsBody)
        if let neededFont = UIFont(name: "SFProText-Light", size: 16) {
            htmlBody?.setFontFace(font: neededFont)
        }
        articleViewController.articleText = htmlBody
        selectedIndexPath.row = indexPath.row
        presentedVC = articleViewController
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
        self.presentedVC?.articleText = htmlBody
    }
    
    func panModalDidDissmiss() {
        //pageControl.isHidden = false
    }
}

protocol PanModalAppearanceDelegate: class {
    func needScrollToDirection(_ direction: UICollectionView.ScrollPosition)
    func panModalDidDissmiss()
}
