//
//  NewsScreenViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.10.2021.
//

import UIKit
import Hero

class NewsScreenViewController: UIViewController {

    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var newsbackgroundImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var smallTitleLabel: UILabel!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleConstraints: [NSLayoutConstraint]!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var blurView: UIView!
    
    var newsData: NewsFeedRow?
    
    var maxHeaderHeight: CGFloat = 340
    var minHeaderHeight: CGFloat = 120
    
    var maxSideTitleConstraint: CGFloat = 60
    var minSideTitleConstraint: CGFloat = 32
    
    var previousScrollOffset: CGFloat = 0
    var tableViewPosition: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupBlurView()
        backButton.setTitle("", for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
//        self.headerHeightConstraint.constant = self.maxHeaderHeight
        updateHeader()
        titleLabel.text = newsData?.headline
        smallTitleLabel.text = newsData?.headline
        subtitleLabel.text = newsData?.byLine
        if let position = tableViewPosition {
            tableView.setContentOffset(position, animated: false)
        } else {
            self.headerHeightConstraint.constant = self.maxHeaderHeight
        }
        print(newsData?.newsContent)
        
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "TextTableViewCell", bundle: nil), forCellReuseIdentifier: "TextTableViewCell")
        tableView.register(UINib(nibName: "ImageTableViewCell", bundle: nil), forCellReuseIdentifier: "ImageTableViewCell")
        tableView.layer.cornerRadius = 16
        tableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tableView.contentInset = tableView.menuButtonContentInset
    }
    
    private func setupBlurView() {
        blurView.layer.cornerRadius = 16
        blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        blurView.addBlurToView()
    }
    
    
}

extension NewsScreenViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsData?.newsContent?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let newsContent = newsData?.newsContent else { return UITableViewCell() }
        //print(newsContent[indexPath.row].type?.lowercased())
        switch newsContent[indexPath.row].type?.lowercased() {
        case "text":
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TextTableViewCell") as? TextTableViewCell else { return UITableViewCell() }
            cell.setupCell(text: newsContent[indexPath.row].body)
            return cell
        case "image":
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell") as? ImageTableViewCell else { return UITableViewCell() }
            cell.delegate = self
            cell.setupCell(imagePath: newsContent[indexPath.row].body)
            return cell
        default:
            return UITableViewCell()
        }
        
        //cell.titleLabelTopConstraint.constant = indexPath.row == 0 ? 40 : 20
        //cell.setupCell(data[indexPath.row])
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - self.previousScrollOffset
        let absoluteTop: CGFloat = 0;
        let absoluteBottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height;
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteBottom
        tableViewPosition = scrollView.contentOffset
        
        print(scrollView.contentOffset.y)
        
        if canAnimateHeader(scrollView) {
            var newHeight = self.headerHeightConstraint.constant
            if isScrollingDown {
                newHeight = max(self.minHeaderHeight, self.headerHeightConstraint.constant - abs(scrollDiff))
            } else if isScrollingUp, scrollView.contentOffset.y <= CGPoint.zero.y {
                newHeight = min(self.maxHeaderHeight, self.headerHeightConstraint.constant + abs(scrollDiff))
            }
            
            if newHeight != self.headerHeightConstraint.constant {
                self.headerHeightConstraint.constant = newHeight
                self.setScrollPosition(position: self.previousScrollOffset)
            }
            
            self.blurView.alpha = min(scrollView.contentOffset.y, 1)
            self.previousScrollOffset = scrollView.contentOffset.y
            self.updateHeader()
        }
    }
    
    func canAnimateHeader(_ scrollView: UIScrollView) -> Bool {
        // Calculate the size of the scrollView when header is collapsed
        let scrollViewMaxHeight = scrollView.frame.height + self.headerHeightConstraint.constant - minHeaderHeight
        
        // Make sure that when header is collapsed, there is still room to scroll
        return scrollView.contentSize.height > scrollViewMaxHeight
    }
    
    func setScrollPosition(position: CGFloat) {
        self.tableView.contentOffset = CGPoint(x: self.tableView.contentOffset.x, y: position)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidStopScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidStopScrolling()
        }
    }
    
    func scrollViewDidStopScrolling() {
        let range = self.maxHeaderHeight - self.minHeaderHeight
        let midPoint = self.minHeaderHeight + (range / 2)
        
        if self.headerHeightConstraint.constant > midPoint {
            expandHeader()
        } else {
            collapseHeader()
        }
    }
    
    func collapseHeader(animated: Bool = true) {
        self.view.layoutIfNeeded()
        if !animated {
            self.headerHeightConstraint.constant = self.minHeaderHeight
            self.updateHeader()
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            self.headerHeightConstraint.constant = self.minHeaderHeight
            self.updateHeader()
            self.view.layoutIfNeeded()
        })
    }
    
    func expandHeader() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.headerHeightConstraint.constant = self.maxHeaderHeight
            // Manipulate UI elements within the header here
            self.updateHeader()
            self.view.layoutIfNeeded()
        })
    }
    
}

//Header
extension NewsScreenViewController {
    func updateHeader() {
        let range = self.maxHeaderHeight - self.minHeaderHeight
        let openAmount = self.headerHeightConstraint.constant - self.minHeaderHeight
        let percentage = openAmount / range
        
        let constraintRange = maxSideTitleConstraint * (1 - (max(percentage - 0.1, 0) / 0.9))
        for i in titleConstraints {
            i.constant = max(constraintRange, minSideTitleConstraint)
            let a = max(min((percentage / 0.6) * minSideTitleConstraint, maxSideTitleConstraint), minSideTitleConstraint)
        }
        //min(max((percentage) * 24, 20), 24 //fontsize
        let titleFont = UIFont.systemFont(ofSize: 20 + percentage * 4)
        self.titleTopConstraint.constant = max(percentage * 100, 14)
        self.smallTitleLabel.alpha = 1 - max(percentage - 0.4, 0) / 0.6
        self.smallTitleLabel.font = titleFont
        self.titleLabel.alpha = max(percentage - 0.4, 0) / 0.6
        self.titleLabel.font = titleFont
        self.subtitleLabel.alpha = max(percentage - 0.4, 0) / 0.6
    }
}

extension NewsScreenViewController: ImageViewDidTappedDelegate {
    func imageViewDidTapped(imageView: UIImageView) {
        let zoomScreen = ImageZoomViewController()
        zoomScreen.hero.isEnabled = true
        zoomScreen.backgroundImage = view.screenshot()
        zoomScreen.image = imageView.image
        zoomScreen.imageID = imageView.restorationIdentifier
        
        navigationController?.hero.isEnabled = true
        navigationController?.heroNavigationAnimationType = .fade
        navigationController?.pushViewController(zoomScreen, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            imageView.alpha = 1
        })
    }
}
