//
//  WhatsNewViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 05.04.2021.
//

import UIKit

class WhatsNewViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var dataProvider: CollaborationDataProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "WhatsNewCell", bundle: nil), forCellReuseIdentifier: "WhatsNewCell")
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "What’s New"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    @objc private func backPressed() {
        self.navigationController?.popViewController(animated: true)
    }

}

extension WhatsNewViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WhatsNewCell", for: indexPath) as? WhatsNewCell
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let whatsNewMoreScreen = WhatsNewMoreViewController()
        whatsNewMoreScreen.dataProvider = dataProvider
        //whatsNewMoreScreen.title = 
        self.navigationController?.pushViewController(whatsNewMoreScreen, animated: true)
    }
    
}
