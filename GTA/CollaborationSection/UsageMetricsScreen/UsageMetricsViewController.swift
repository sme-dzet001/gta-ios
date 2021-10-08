//
//  UsageMetricsViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.04.2021.
//

import UIKit
import WebKit

protocol ChartDimensions: AnyObject {
    var optimalHeight: CGFloat { get }
}

class UsageMetricsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var appTextField: CustomTextField!
    
    private let pickerView = UIPickerView()
    
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var errorLabel: UILabel = UILabel()
    var dataProvider: CollaborationDataProvider?
    
    private var isKeyboardShow: Bool = false
    
    var charts: [MetricsPosition?] {
        return dataProvider?.chartsPosition ?? []
    }
    
    private var chartDimensionsDict: [Int : ChartDimensions] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        addObservers()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.barTintColor = .white
        
        setUpTableView()
        setUpTextField()
        setUpNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel)
        getChartsData()
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIApplication.keyboardWillHideNotification, object: nil)
    }
    
    private func setUpTableView() {
        tableView.contentInset = tableView.menuButtonContentInset
        tableView.register(UINib(nibName: "ActiveUsersByFunctionCell", bundle: nil), forCellReuseIdentifier: "ActiveUsersByFunctionCell")
        tableView.register(UINib(nibName: "TeamChatUsersCell", bundle: nil), forCellReuseIdentifier: "TeamChatUsersCell")
        tableView.register(UINib(nibName: "TeamsByFunctionsTableViewCell", bundle: nil), forCellReuseIdentifier: "TeamsByFunctionsTableViewCell")
        tableView.register(UINib(nibName: "ActiveUsersTableViewCell", bundle: nil), forCellReuseIdentifier: "ActiveUsersTableViewCell")
    }
    
    @objc private func didBecomeActive() {
        getChartsData()
        hideKeyboard()
    }
    
    @objc private func keyboardWillShow() {
        isKeyboardShow = true
    }
    
    @objc private func keyboardWillHide() {
        isKeyboardShow = false
    }
    
    private func setUpTextField() {
        pickerView.delegate = self
        pickerView.dataSource = self
        appTextField.inputView = pickerView
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44))
        toolbar.barStyle = .default
        toolbar.backgroundColor = .white
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([flexible, doneButton], animated: true)
        appTextField.inputAccessoryView = toolbar
    }
    
    @objc private func doneAction() {
        updateChartsData()
        reloadData()
        view.endEditing(true)
    }
    
    private func updateChartsData() {
        let selectedIndex = pickerView.selectedRow(inComponent: 0)
        guard let availableApps = dataProvider?.availableApps, availableApps.count > selectedIndex else { return }
        let app = availableApps[selectedIndex]
        dataProvider?.getMetricsDataForApp(app)
        setTextFieldText(app)
        dataProvider?.selectedApp = app
        tableView.reloadData()
    }
    
    @objc private func getChartsData() {
        startAnimation()
        dataProvider?.getUsageMetrics {[weak self] isFromCache, dataWasChanged, errorCode, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.stopAnimation()
                    self?.reloadData()
                } else if error != nil, !isFromCache {
                    self?.stopAnimation(with: error)
                }
            }
        }
    }
    
    private func reloadData() {
        if let isChartDataEmpty = dataProvider?.isChartDataEmpty, isChartDataEmpty {
            return
        }
        self.tableView.reloadData()
    }
    
    private func startAnimation() {
        self.errorLabel.isHidden = true
        self.tableView.alpha = 0
        self.appTextField.alpha = 0
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation(with error: Error? = nil) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.errorLabel.isHidden = error == nil
            self.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
            self.tableView.alpha = error == nil ? 1 : 0
            let selectedApp = self.dataProvider?.selectedApp ?? ""
            self.setTextFieldText(selectedApp)
            let row = self.dataProvider?.availableApps.firstIndex(of: selectedApp) ?? 0
            self.pickerView.selectRow(row, inComponent: 0, animated: false)
            self.appTextField.alpha = self.tableView.alpha
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func setTextFieldText(_ text: String) {
        var firstPartAttributes: [NSAttributedString.Key : Any]? = [:]
        if let firstPartFont = UIFont(name: "SFProText-Regular", size: 14) {
            firstPartAttributes?[.font] = firstPartFont
        }
        firstPartAttributes?[.foregroundColor] = UIColor(hex: 0x8E8E93)
        let firstPart = NSMutableAttributedString(string: "App: ", attributes: firstPartAttributes)
        var secondPartAttributes: [NSAttributedString.Key : Any]? = [:]
        if let secondPartFont = UIFont(name: "SFProText-Semibold", size: 14) {
            secondPartAttributes?[.font] = secondPartFont
        }
        secondPartAttributes?[.foregroundColor] = UIColor.black
        let secondPart = NSAttributedString(string: text, attributes: secondPartAttributes)
        firstPart.append(secondPart)
        appTextField.attributedText = firstPart
        appTextField.setIconForPicker(for: self.view.frame.width, isCharts: true)
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        tlabel.text = "Usage Metrics"
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }
    
    @objc private func backPressed() {
        if isKeyboardShow {
            hideKeyboard()
            return
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillHideNotification, object: nil)
    }

}

extension UsageMetricsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return charts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let chartDimensions = chartDimensionsDict[indexPath.row] {
            return chartDimensions.optimalHeight
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < charts.count else { return UITableViewCell() }
        let data = charts[indexPath.row]
        switch data {
        case is TeamsChatUserData:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TeamChatUsersCell") as? TeamChatUsersCell else { return UITableViewCell() }
            chartDimensionsDict[indexPath.row] = cell
            cell.chartData = dataProvider?.horizontalChartData
            return cell
        case is ChartStructure:
            guard let chart = data as? ChartStructure else { return UITableViewCell() }
            if chart.chartType == .line {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveUsersTableViewCell") as? ActiveUsersTableViewCell else { return UITableViewCell() }
                chartDimensionsDict[indexPath.row] = cell
                cell.chartData = dataProvider?.activeUsersLineChartData
                cell.updateData()
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveUsersByFunctionCell") as? ActiveUsersByFunctionCell else { return UITableViewCell() }
                cell.setUpBarChartView(with: dataProvider?.verticalChartData)
                chartDimensionsDict[indexPath.row] = cell
                return cell
            }
        case is TeamsByFunctionsLineChartData:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TeamsByFunctionsTableViewCell") as? TeamsByFunctionsTableViewCell else { return UITableViewCell() }
            chartDimensionsDict[indexPath.row] = cell
            cell.chartsData = dataProvider?.teamsByFunctionsLineChartData
            cell.updateData()
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        hideKeyboard()
    }
    
}

extension UsageMetricsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataProvider?.availableApps.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let apps = dataProvider?.availableApps, apps.count > row else {  return nil }
        return apps[row]
    }
   
}

// TODO: Find better way

protocol TeamsByFunctionsDataChangedDelegate: AnyObject {
    func teamsByFunctionsDataChanged(newData: TeamsByFunctionsLineChartData?)
}

protocol VerticalBarChartDataChangedDelegate: AnyObject {
    func setUpBarChartView(with chartStructure: ChartStructure?)
}

protocol HorizontallBarChartDataChangedDelegate: AnyObject {
    func verticalBarChartDataChanged(newData: TeamsChatUserData?)
}

protocol ActiveUsersDataChangedDelegate: AnyObject {
    func activeUsersDataChanged(newData: ChartStructure?)
}
