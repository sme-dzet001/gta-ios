//
//  TabBarController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 30.09.2021.
//

import UIKit

class CustomTabBarController: UITabBarController {
    
    weak var indexDelegate: TabBarIndexChanged?
    
    override var selectedViewController: UIViewController? {
        didSet {
            indexDelegate?.changeIndex(index: selectedIndex)
        }
    }
    
    override var selectedIndex: Int {
        didSet {
            indexDelegate?.changeIndex(index: selectedIndex)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

protocol TabBarIndexChanged: AnyObject {
    func changeIndex(index: Int)
}
