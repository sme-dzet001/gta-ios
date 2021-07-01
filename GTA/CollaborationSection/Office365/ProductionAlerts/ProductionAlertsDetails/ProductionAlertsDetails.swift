//
//  ProductionAlertsDetails.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.04.2021.
//

import UIKit
import PanModal

class ProductionAlertsDetails: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var blurView: UIView!
    
    var alertData: ProductionAlertsRow?
    private var dataSource: [[String : String]] = []
    private var heightObserver: NSKeyValueObservation?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        setUpTableView()
        setUpDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBlurToView()
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.configureBlurViewPosition()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureBlurViewPosition()
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "AlertDetailsHeaderCell", bundle: nil), forCellReuseIdentifier: "AlertDetailsHeaderCell")
        tableView.register(UINib(nibName: "AlertDetailsCell", bundle: nil), forCellReuseIdentifier: "AlertDetailsCell")
    }
    
    private func setUpDataSource() {
        dataSource.append(["title" : "title"])
        if let start = alertData?.startDateString?.getFormattedDateStringForMyTickets() {
            dataSource.append(["Notification Date" : start])
        }
        if let close = alertData?.closeDateString?.getFormattedDateStringForMyTickets() {
            dataSource.append(["Close Date" : close])
        }
//        if let duration = alertData?.d {
//            dataSource.append(["Duration" : duration])
//        }
        if let summary = alertData?.summary {
            dataSource.append(["Summary" : summary])
        }
    }
    
    func addBlurToView() {
        blurView.isHidden = false
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.bounds
        gradientMaskLayer.colors = [UIColor.white.withAlphaComponent(0.0).cgColor, UIColor.white.withAlphaComponent(0.3) .cgColor, UIColor.white.withAlphaComponent(1.0).cgColor]
        gradientMaskLayer.locations = [0, 0.1, 0.9, 1]
        blurView.layer.mask = gradientMaskLayer
    }
    
    private func configureBlurViewPosition() {
        guard position > 0 else { return }
        blurView.frame.origin.y = position - blurView.frame.height
        self.view.layoutIfNeeded()
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        heightObserver?.invalidate()
    }
    
}

extension ProductionAlertsDetails: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertDetailsHeaderCell", for: indexPath) as? AlertDetailsHeaderCell
            cell?.alertNumberLabel.text = alertData?.ticketNumber
            cell?.alertTitleLabel.text = alertData?.description
            cell?.setStatus(alertData?.status)
            return cell ?? UITableViewCell()
        }
        guard dataSource.count > indexPath.row, let key = dataSource[indexPath.row].keys.first else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlertDetailsCell", for: indexPath) as? AlertDetailsCell
        cell?.titleLabel.text = key
        cell?.descriptionLabel.text = dataSource[indexPath.row][key]
        return cell ?? UITableViewCell()
    }
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height) {
            blurView.isHidden = true
        } else {
            blurView.isHidden = false
        }
    }
    
}

extension ProductionAlertsDetails: PanModalPresentable {
    
    var panScrollable: UIScrollView? {
        return tableView
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var topOffset: CGFloat {
        if let keyWindow = UIWindow.key {
            return keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    var shortFormHeight: PanModalHeight {
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return PanModalHeight.contentHeight(coefficient - (view.window?.safeAreaInsets.bottom ?? 0))
    }
    
    var position: CGFloat {
        return UIScreen.main.bounds.height - (self.presentationController?.presentedView?.frame.origin.y ?? 0.0)
    }
    
    func willTransition(to state: PanModalPresentationController.PresentationState) {
        switch state {
        case .shortForm:
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = 1
            }
        default:
            return
        }
    }
    
}
