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
    
    var dataProvider: MyAppsDataProvider?
    
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
        loadProductionAlertsData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if loadProductionAlertsInProgress.loadAllAppsInProgress || loadProductionAlertsInProgress.loadMyAppsInProgress {
            dataProvider?.forceUpdateProductionAlerts = false
            dataProvider?.activeProductionAlertId = nil
            dataProvider?.activeProductionAlertAppName = nil
        }
    }
    
    private var loadProductionAlertsInProgress: (loadAllAppsInProgress: Bool, loadMyAppsInProgress: Bool) = (false, false) {
        didSet {
            if loadProductionAlertsInProgress == (false, false) {
                if let appName = dataProvider?.activeProductionAlertAppName, let alertsData = dataProvider?.alertsData, let alertsDataForApp = alertsData[appName], let activeProductionAlertId = dataProvider?.activeProductionAlertId, let alertData = alertsDataForApp.first(where: {$0.ticketNumber == activeProductionAlertId}) {
                    self.alertData = alertData
                    setUpDataSource()
                }
                dataProvider?.forceUpdateProductionAlerts = false
                dataProvider?.activeProductionAlertId = nil
                dataProvider?.activeProductionAlertAppName = nil
            }
            tableView.reloadData()
        }
    }
    
    private func loadProductionAlertsData() {
        if let forceUpdateProductionAlerts = dataProvider?.forceUpdateProductionAlerts, forceUpdateProductionAlerts {
            loadProductionAlertsInProgress = (true, true)
            dataProvider?.getAllAppsIgnoringCache(completion: {[weak self] dataWasChanged, errorCode, error in
                DispatchQueue.main.async {
                    self?.loadProductionAlertsInProgress.loadAllAppsInProgress = false
                }
            })
            dataProvider?.getMyAppsStatusIgnoringCache(completion: {[weak self] dataWasChanged, errorCode, error in
                DispatchQueue.main.async {
                    self?.loadProductionAlertsInProgress.loadMyAppsInProgress = false
                }
            })
        } else {
            dataProvider?.forceUpdateProductionAlerts = false
            dataProvider?.activeProductionAlertId = nil
            dataProvider?.activeProductionAlertAppName = nil
            setUpDataSource()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBlurToView()
        addHeightObservation()
        configureBlurViewPosition(isInitial: true)
    }
    
    override func viewDidLayoutSubviews() {
        configureBlurViewPosition()
    }
    
    private func configureBlurViewPosition(isInitial: Bool = false) {
        guard position > 0 else { return }
        blurView.frame.origin.y = !isInitial ? position - blurView.frame.height: initialHeight - 44
        self.view.layoutIfNeeded()
    }
    
    private func addHeightObservation() {
        heightObserver = self.presentationController?.presentedView?.observe(\.frame, changeHandler: { [weak self] (_, _) in
            self?.configureBlurViewPosition()
        })
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
        if alertData?.status == .closed, let close = alertData?.closeDateString?.getFormattedDateStringForMyTickets() {
            dataSource.append(["Close Date" : close])
        }
        if let duration = alertData?.duration {
            dataSource.append(["Estimated Duration" : duration])
        }
        if let summary = alertData?.description {
            dataSource.append(["Summary" : summary])
        }
        if let impactedSystems = alertData?.impactedSystems {
            dataSource.append(["Affected Systems" : impactedSystems])
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
    
    private func handleBlurShowing(animated: Bool) {
        let isReachedBottom = tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height).rounded(.towardZero)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.blurView.alpha = isReachedBottom ? 0 : 1
            }
        } else {
            blurView.alpha = isReachedBottom ? 0 : 1
        }
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
        return (dataSource.count > 0) ? dataSource.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if loadProductionAlertsInProgress.loadAllAppsInProgress || loadProductionAlertsInProgress.loadMyAppsInProgress {
            return createLoadingCell(withBottomSeparator: false)
        }
        guard dataSource.count > indexPath.row, let key = dataSource[indexPath.row].keys.first else {
            return createErrorCell(with: "No data available")
        }
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlertDetailsHeaderCell", for: indexPath) as? AlertDetailsHeaderCell
            cell?.alertNumberLabel.text = alertData?.ticketNumber
            cell?.alertTitleLabel.text = alertData?.summary
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
        handleBlurShowing(animated: true)
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
    
    var initialHeight: CGFloat {
        let coefficient = (UIScreen.main.bounds.height - (UIScreen.main.bounds.width * 0.82)) + 10
        return coefficient - (view.window?.safeAreaInsets.bottom ?? 0)
    }
    
    var shortFormHeight: PanModalHeight {
        guard !UIDevice.current.iPhone5_se else { return .maxHeight }
        return PanModalHeight.contentHeight(initialHeight)
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
