//
//  UsageMetricsViewController.swift
//  GTA
//
//  Created by Margarita N. Bock on 09.04.2021.
//

import UIKit
import WebKit

class UsageMetricsViewController: UIViewController {
    
    private var usageMetricsWebView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.barTintColor = .white
        
        setUpNavigationItem()

        usageMetricsWebView = WKWebView(frame: CGRect.zero)
        usageMetricsWebView.translatesAutoresizingMaskIntoConstraints = false
        usageMetricsWebView.scrollView.showsVerticalScrollIndicator = false
        usageMetricsWebView.scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(usageMetricsWebView)
        NSLayoutConstraint.activate([
            usageMetricsWebView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            usageMetricsWebView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            usageMetricsWebView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            usageMetricsWebView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
        //loadUsageMetrics()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        loadUsageMetrics()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        self.tabBarController?.tabBar.isHidden = false
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
        self.navigationController?.popViewController(animated: true)
    }
    
    private func loadUsageMetrics() {
        
        ///iframe
        
        /*let htmlStart = "<HTML><HEAD><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, shrink-to-fit=no\"></HEAD><BODY>"
        let htmlEnd = "</BODY></HTML>"
        let htmlBodyStr = "<iframe width=\"\(usageMetricsWebView.frame.size.width)\" height=\"\(usageMetricsWebView.frame.size.height)\" src=\"https://app.powerbi.com/view?r=eyJrIjoiNmVhZTljOTQtZDRhOS00M2YwLTljMDAtOTgwYTY0NTI5ZGI1IiwidCI6ImYwYWZmM2I3LTkxYTUtNGFhZS1hZjcxLWM2M2UxZGRhMjA0OSIsImMiOjh9\"frameborder=\"0\" allowFullScreen=\"true\"></iframe>"
        let htmlFullStr = "\(htmlStart)\(htmlBodyStr)\(htmlEnd)"
        usageMetricsWebView.loadHTMLString(htmlFullStr, baseURL: Bundle.main.bundleURL)*/
        
        ///direct link loading
        
        if let url = URL(string: "https://app.powerbi.com/view?r=eyJrIjoiNmVhZTljOTQtZDRhOS00M2YwLTljMDAtOTgwYTY0NTI5ZGI1IiwidCI6ImYwYWZmM2I3LTkxYTUtNGFhZS1hZjcxLWM2M2UxZGRhMjA0OSIsImMiOjh9") {
            let request = URLRequest(url: url)
            usageMetricsWebView.load(request)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
