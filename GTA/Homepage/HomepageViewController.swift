//
//  HomepageViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.11.2020.
//

import UIKit
import AdvancedPageControl

class HomepageViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: AdvancedPageControlView!
    
    var dataSource: [NewsItem] = [NewsItem(image: "covid", newsLabel: "What is the current situation?"), NewsItem(image: "music", newsLabel: "New Sony Music Metrics Report Available"), NewsItem(image: "tech", newsLabel: "Latest Global Technology News")]
    var homepageTableVC: HomepageTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        pageControl.drawer = ExtendedDotDrawer(numberOfPages: dataSource.count,  height: 5, width: CGFloat(dataSource.count) * 1.5, dotsColor: .white)
        pageControl.drawer.currentItem = 0
        setNeedsStatusBarAppearanceUpdate()
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
        collectionView.register(UINib(nibName: "NewsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "NewsCollectionViewCell")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "embedTable" {
            homepageTableVC = segue.destination as? HomepageTableViewController
            homepageTableVC?.delegate = self
        }
    }
    
    @IBAction func unwindToHomePage(segue: UIStoryboardSegue) {
    }
}

extension HomepageViewController: HomepageMainDelegate {
    func navigateToOfficeStatus() {
        performSegue(withIdentifier: "showOfficeStatus", sender: nil)
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
            cell.dateLabel.text = dateFormatterPrint.string(from: Date())
            return cell
        } else {
            return UICollectionViewCell()
        }
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

// temp
struct NewsItem {
    var image: String
    var newsLabel: String
    var newsDate: Date? = nil
}
