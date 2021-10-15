//
//  ImageZoomViewController.swift
//  GTA
//
//  Created by Артем Хрещенюк on 15.10.2021.
//

import UIKit
import Hero

class ImageZoomViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var zoomImage: UIImageView!
    @IBOutlet weak var snapshotImage: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    
    var imageID: String?
    var image: UIImage?
    var backgroundImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.setTitle("", for: .normal)
        snapshotImage.image = backgroundImage
        
        zoomImage.image = image
        zoomImage.heroID = imageID
        setupScrollView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        menuButton(enable: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        menuButton(enable: true)
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
//        scrollView.decelerationRate = UIScrollView.DecelerationRate.fast
//        scrollView.alwaysBounceVertical = true
//        scrollView.alwaysBounceHorizontal = true
    }
    
    private func menuButton(enable: Bool) {
        guard let mainVC = self.tabBarController?.navigationController?.viewControllers.first(where: { $0 is MainViewController}) as? MainViewController else {return}
        mainVC.menuButton.alpha = enable ? 1 : 0
    }
    
}

extension ImageZoomViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImage
    }
}
