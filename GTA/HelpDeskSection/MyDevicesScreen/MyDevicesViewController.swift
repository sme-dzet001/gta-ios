//
//  MyDevicesViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 17.11.2020.
//

import UIKit

class MyDevicesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var myDevicesData: [DeviceData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }

    private func setUpNavigationItem() {
        navigationItem.title = "My Devices"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = 356
        tableView.register(UINib(nibName: "DeviceCell", bundle: nil), forCellReuseIdentifier: "DeviceCell")
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

}

extension MyDevicesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myDevicesData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as? DeviceCell {
            return cell
        }
        return UITableViewCell()
    }
    
}

struct DeviceData {
    var deviceType: DeviceType
    var isActive: Bool?
    var deviceModel: String?
    var deviceName: String?
    var deviceNumber: String?
    var serialNumber: String?
}

enum DeviceType {
    case phone
    case tablet
}
