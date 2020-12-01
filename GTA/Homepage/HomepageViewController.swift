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
    @IBOutlet weak var pageControl: AdvancedPageControlView!
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var dataSource: [NewsItem] = [NewsItem(image: "covid", newsLabel: "What is the current situation?"), NewsItem(image: "music", newsLabel: "New Sony Music Metrics Report Available"), NewsItem(image: "tech", newsLabel: "Latest Global Technology News")]
    var homepageTableVC: HomepageTableViewController?
    
    private var presentedVC: ArticleViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        setUpPageControl()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func setUpPageControl() {
        
        let inactiveColor = UIColor(red: 147.0 / 255.0, green: 130.0 / 255.0, blue: 134.0 / 255.0, alpha: 1.0)
        pageControl.drawer = ExtendedDotDrawer(numberOfPages: dataSource.count,  height: 4, width: 6, space: 6, dotsColor: inactiveColor, borderColor: inactiveColor, indicatorBorderColor: .white)
        pageControl.drawer.currentItem = 0
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "embedTable" {
            homepageTableVC = segue.destination as? HomepageTableViewController
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
    }
    
}

extension HomepageViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCollectionViewCell", for: indexPath) as? NewsCollectionViewCell {
            cell.imageView.image = UIImage(named: dataSource[indexPath.row].image)
            cell.titleLabel.text = dataSource[indexPath.row].newsLabel
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = String.neededDateFormat
            // hardcoding date similar to Figma for now
            cell.dateLabel.text = "10:30 +5 GTM Wed 15" //dateFormatterPrint.string(from: Date())
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
        articleViewController.articleText = dataSource[indexPath.row].articleText
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
        if scrollPosition == .left && selectedIndexPath.row < dataSource.count - 1 {
            selectedIndexPath.row += 1
        } else if scrollPosition == .right && selectedIndexPath.row > 0 {
            selectedIndexPath.row -= 1
        } else {
            return
        }
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.selectItem(at: selectedIndexPath, animated: true, scrollPosition: scrollPosition)
        self.presentedVC?.articleText = selectedIndexPath.row % 2 == 0 ? self.dataSource[self.selectedIndexPath.row].articleText : "From end of August 2020, Swedish authorities are performing daily data consolidation leading to data retro-corrections. From week 38, the Swedish Public Health Agency will update COVID-19 daily data four times per week on Tuesday–Friday. \n\nHence, the cumulative figures and related outputs include cases and deaths from the previous 14 days with available data at the time of data collection.\n\nOn 10 September 2020, Jersey reclassified nine cases as old infections resulting in negative cases reported on 11 September 2020. \n\nAs of 7 September 2020, there is a negative number of cumulative cases in Ecuador due to the removal of cases detected from rapid tests. In addition, the total number of reported COVID-19 deaths has shifted to include both probable and confirmed deaths, which lead to a steep increase on the 7 Sep. \n\nAs of 7 September 2020, there is a negative number of cumulative cases in Ecuador due to the removal of cases detected from rapid tests."// for d
    }
    
    func panModalDidDissmiss() {
        //pageControl.isHidden = false
    }
}

protocol PanModalAppearanceDelegate: class {
    func needScrollToDirection(_ direction: UICollectionView.ScrollPosition)
    func panModalDidDissmiss()
}

// temp
struct NewsItem {
    var image: String
    var newsLabel: String
    var newsDate: Date? = nil
    var articleText: String = "On 10 September 2020, Jersey reclassified nine cases as old infections resulting in negative cases reported on 11 September 2020. \n\nAs of 7 September 2020, there is a negative number of cumulative cases in Ecuador due to the removal of cases detected from rapid tests. In addition, the total number of reported COVID-19 deaths has shifted to include both probable and confirmed deaths, which lead to a steep increase on the 7 Sep. \n\nAs of 7 September 2020, there is a negative number of cumulative cases in Ecuador due to the removal of cases detected from rapid tests. In addition, the total number of reported COVID-19 deaths has shifted to include both probable and confirmed deaths, which lead to a steep increase on the 7 Sep."
}
