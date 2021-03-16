//
//  AppTipsAndTricksViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.03.2021.
//

import UIKit
import PDFKit

class AppTipsAndTricksViewController: UIViewController {

    @IBOutlet var pdfView: PDFView!
    @IBOutlet weak var errorLabel: UILabel!
    private var documentData: Data?
    
    var appName: String?
    var pdfUrlString: String?
    private var dataProvider: MyAppsDataProvider = MyAppsDataProvider()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = .white
        setUpNavigationItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpPDFView()
        startAnimation()
        getAppTipsAndTricks()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAnimation()
    }
    
    private func setUpNavigationItem() {
        let tlabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        let titleText = appName != nil ? "\(appName!)\nTips & Tricks" : "Tips & Tricks"
        tlabel.text = titleText
        tlabel.textColor = UIColor.black
        tlabel.textAlignment = .center
        tlabel.font = UIFont(name: "SFProDisplay-Medium", size: 20.0)
        tlabel.backgroundColor = UIColor.clear
        tlabel.minimumScaleFactor = 0.6
        tlabel.numberOfLines = 2
        tlabel.adjustsFontSizeToFitWidth = true
        self.navigationItem.titleView = tlabel
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(self.backPressed))
    }
    
    private func setUpPDFView() {
        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.displayMode = .singlePageContinuous
    }
    
    private func startAnimation() {
        self.pdfView.alpha = 0
        self.errorLabel.isHidden = true
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationController?.addAndCenteredActivityIndicator(activityIndicator)
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimation() {
        DispatchQueue.main.async {
            if let _ = self.pdfView.document {
                self.pdfView.alpha = 1
            }
            self.activityIndicator.stopAnimating()
            self.activityIndicator.removeFromSuperview()
        }
    }
    
    private func getAppTipsAndTricks() {
        dataProvider.getPDFData(appName: appName ?? "", urlString: pdfUrlString ?? "") {[weak self] (data, code, error) in
            if let _ = error {
                self?.showErrorLabel(with: (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong")
                return
            }
            self?.showPDFView(with: data)
            self?.stopAnimation()
        }
    }
    
    private func showErrorLabel(with text: String) {
        DispatchQueue.main.async {
            self.stopAnimation()
            self.errorLabel.text = text
            self.errorLabel.isHidden = false
        }
    }
    
    private func showPDFView(with data: Data?) {
        guard let _ = data else { return }
        DispatchQueue.main.async {
            if data != self.documentData {
                self.pdfView.document = PDFDocument(data: data!)
                self.documentData = data
            }
        }
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension AppTipsAndTricksViewController: PDFViewDelegate {
    
}
