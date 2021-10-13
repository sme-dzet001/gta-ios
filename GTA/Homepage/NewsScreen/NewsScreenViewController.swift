//
//  NewsScreenViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 07.10.2021.
//

import UIKit

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
    
    var maxHeaderHeight: CGFloat = 340
    var minHeaderHeight: CGFloat = 120
    
    var maxSideTitleConstraint: CGFloat = 60
    var minSideTitleConstraint: CGFloat = 32
    
    var previousScrollOffset: CGFloat = 0
    var headerData: HeaderData?
    var newsData: [NewsData]?
    
    let headerDataOne = HeaderData(title: "How Sony Music uses data to connect artists with fans", subtitle: "Forbes Content Studio Forbes Staff Forbes Content Merketing")
    let headerDataTwo = HeaderData(title: "Real time Trends", subtitle: "Forbes Content Studio Forbes Staff Forbes Content Merketing")
    
    let newsDataOne: [NewsData] = [
        NewsData(title: "New Side-by-side and Reporter Presenter modes with desktop and window sharing", text: "Two new presenter modes are now coming available. Reporter places content as a visual aid above your shoulder like a news story. Side-by-side displays your video feed next to your content. You can now select a mode that fits your needs and promotes a more engaging presentation and consumption experience.", images: [UIImage(named: "newsImage1")!]),
        NewsData(title: "Spam Notification in Call Toast", text: "The spam call notification feature automatically evaluates incoming calls and identifies probable spam calls as “spam likely” in the call toast.  Users still have the option to answer or reject the call, and all “spam likely” calls (regardless of whether they were answered or rejected) will also be reflected in the call history list.", images: [UIImage(named: "newsImage2")!]),
        NewsData(title: "Music Mode for Teams", text: "Teams’ high fidelity music mode enables a richer sounding experience for audio through the pc’s microphone input.  Users will have the option to turn off echo cancellation, noise suppression, and gain control. The improved fidelity is best experienced through professional microphones and headphones or high-quality external loudspeakers (Bluetooth headsets will not provide the best quality sound reproduction). Teams settings must be enabled before joining a call or meeting.  An eighth note symbol will appear in the control bar to toggle music mode on and off. This setting is perfect for live musical performances and other times when transmitting high quality music to an online audience.  Audio generated from a sound source other than that of the microphone, for instance playing an audio or video stream, will not benefit from this feature.", images: [UIImage(named: "newsImage3")!]),
        NewsData(title: "New default settings when opening Office files", text: "This new feature allows users to set a default of browser, desktop or Teams when opening Office files (Word, Excel, and Power Point) that are shared in Teams. The desktop setting can be selected if the user has Office version 16 or newer installed and activated.", images: [UIImage(named: "newsImage4")!]),
        NewsData(title: "Breakout rooms: Pre-meeting room creation and participant assignment", text: "The ability for meeting organizers to pre-create rooms ahead of a meeting start and perform participant assignment tasks (both auto and manual) in advance. This is rolling out on desktop only.", images: [UIImage(named: "newsImage5")!]),
        NewsData(title: "SharePoint Collapsible Sections", text: "This new feature will allow users to create rich, information-dense SharePoint pages. You’ll have the ability to show page sections in an accordion view (collapsed or expanded) or as tabs. The accordion view will be collapsed by default but can be set to show expanded.", images: [UIImage(named: "newsImage6")!]),
        NewsData(title: "Chat Bubbles", text: "Chat has become a lively space for conversation and idea-sharing and offers an option for people to participate in the discussion without having to jump in verbally. With chat bubbles, meeting participants can follow chat on the main screen of a meeting.", images: [UIImage(named: "newsImage7")!]),
        NewsData(title: "Teams: Lock Meetings", text: "In the Teams meetings desktop app experience, organizers can choose to lock their meetings to prevent subsequent join attempts. Anyone attempting to join a lock meeting from any device will be informed that the meeting is locked. ", images: nil),
        NewsData(title: "Forms: Split sending and sharing entry point", text: "To remove the confusion between collecting response from others and collaborating with others, we decouple entry point of sending and sharing into separate paths.", images: nil),
        NewsData(title: "Streams: New Stream hub page", text: "You can now find the recordings of your meetings and of the ones that have been shared with you using the new 'Stream' hub experience.  'Stream (Classic)' is being retired next year.", images: nil),
        NewsData(title: "Microsoft Forms new App 'Polls' in Teams", text: "Forms will release a more discoverable app named 'Polls' in Teams. Adding polls to Teams chats/meetings via this new “Polls” app will be the same experience as before (via the Forms app), but now it’s under a new app name and Teams-branded icon.", images: nil)
    ]
    
    let newsDataTwo: [NewsData] = [
        NewsData(title: nil, text: "In an effort towards consolidation and efficiency, the old Artist 360 application is now integrated into the Artist Portal as Real Time Trends.The Artist Portal is a desktop and mobile application used by our artists and artist managers to review Real Time Earnings, perform Real Time Advances and Cash-Outs, and to view consumption metrics through Real Time Trends. The Real Time Trends module of the Artist Portal is now open to all internal users on both mobile and desktop allowing instant access to high level stats on all Sony Music repertoire. Real Time Trends makes it easy for users to gain valuable insights into an artist's overall performance by making data available from more than 20+ Top Global Partners (and more to come!). There are daily, weekly, and all-time sales metrics on an artist, album, and track level.  For partners that provide more detailed reporting, we are able to expose metrics related to source of stream and playlist activity.  Lastly, to make searching more manageable, multiple versions of the same track are automatically combined to consolidate sales metrics on an overall song level.", images: [UIImage(named: "newsImage8")!, UIImage(named: "newsImage9")!]),
        NewsData(title: "The following are mobile screenshots to illustrate some of the more popular features:", text: nil, images: [UIImage(named: "newsImage10")!,UIImage(named: "newsImage11")!,UIImage(named: "newsImage12")!]),
        NewsData(title: nil, text: "We welcome everyone to try out the new Real Time Trends section of the Artist Portal by downloading the app or through the browser as seen below.  SME users can simply login with their email and network password.", images: [UIImage(named: "newsImage13")!])
    ]
    
    var heightMultiplier = 0.47
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupBlurView()
        backButton.setTitle("", for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.headerHeightConstraint.constant = self.maxHeaderHeight
        updateHeader()
        titleLabel.text = headerData?.title
        smallTitleLabel.text = headerData?.title
        subtitleLabel.text = headerData?.subtitle
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "NewsScreenTableViewCell", bundle: nil), forCellReuseIdentifier: "NewsScreenTableViewCell")
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
        return newsData?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsScreenTableViewCell", for: indexPath) as? NewsScreenTableViewCell, let data = newsData else { return UITableViewCell() }
        cell.titleLabelTopConstraint.constant = indexPath.row == 0 ? 40 : 20
        cell.setupCell(data[indexPath.row])
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - self.previousScrollOffset
        let absoluteTop: CGFloat = 0;
        let absoluteBottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height;
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteBottom
        
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
    
    func collapseHeader() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2, animations: {
            self.headerHeightConstraint.constant = self.minHeaderHeight
            // Manipulate UI elements within the header here
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

struct NewsData {
    var title: String?
    var text: String?
    var images: [UIImage]?
}

struct HeaderData {
    var title: String?
    var subtitle: String?
}
