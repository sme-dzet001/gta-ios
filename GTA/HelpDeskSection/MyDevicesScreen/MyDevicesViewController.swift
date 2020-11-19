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
        setHardCodeData()
    }

    private func setUpNavigationItem() {
        navigationItem.title = "My Devices"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
    }
    
    private func setUpTableView() {
        tableView.rowHeight = 356
        tableView.register(UINib(nibName: "DeviceCell", bundle: nil), forCellReuseIdentifier: "DeviceCell")
    }
    
    private func setHardCodeData() {
        myDevicesData = [
            DeviceData(deviceType: .phone, deviceTitle: "JDiddyiPhone", isActive: true, deviceModel: "Apple", deviceName: "Iphone 11 Pro Max", deviceNumber: "M01234567", serialNumber: "00112233445566778899"),
            DeviceData(deviceType: .tablet, deviceTitle: "JDiddyiPad", isActive: false, deviceModel: "Apple", deviceName: "Ipad Pro 2019", deviceNumber: "A03224660", serialNumber: "03114233445566758859"),
            DeviceData(deviceType: .phone, deviceTitle: "JDiddySamsung", isActive: false, deviceModel: "Samsung", deviceName: "A51", deviceNumber: "C15244557", serialNumber: "05112733485568773891"),
            DeviceData(deviceType: .phone, deviceTitle: "Admin iPhone", isActive: true, deviceModel: "Apple", deviceName: "Iphone SE (2nd generation)", deviceNumber: "T00034461", serialNumber: "10142223433567770809")
        ]
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
            cell.delegate = self
            cell.setUpCell(with: myDevicesData[indexPath.row], hideSeparator: indexPath.row == myDevicesData.count - 1)
            return cell
        }
        return UITableViewCell()
    }
    
}

extension MyDevicesViewController: DeviceCellDelegate {
    
    func deviceCellSwitchStateWasChanged(_ cell: DeviceCell, to active: Bool) {
        if let cellIndexPath = tableView.indexPath(for: cell) {
            myDevicesData[cellIndexPath.row].isActive = active
        }
    }
    
}

struct DeviceData {
    var deviceType: DeviceType
    var deviceTitle: String?
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
