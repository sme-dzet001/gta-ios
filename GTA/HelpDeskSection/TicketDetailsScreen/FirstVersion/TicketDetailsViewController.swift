//
//  TicketDetailsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit
import PanModal

class TicketDetailsViewController: UIViewController, PanModalPresentable {
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    
    var panScrollable: UIScrollView? {
        return tableView
    }
    
    var shortFormHeight: PanModalHeight {
        return initialHeight
    }
    
    var allowsExtendedPanScrolling: Bool {
        return true
    }
    
    var longFormHeight: PanModalHeight {
        return .maxHeight
    }
    
    var initialHeight: PanModalHeight = .maxHeight
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var dataSource: TicketData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpTextViewIfNeeded()
    }
    
    private func setUpTextViewIfNeeded() {
        guard dataSource?.status == .open else { return }
        let textView = SendMessageView.instanceFromNib()
        textView.setUpTextView()
        var coefficient: CGFloat = 0
        if #available(iOS 13.0, *) {
            coefficient = view.window?.safeAreaInsets.top ?? 0 > 24 ? 86 : 66
        } else {
            coefficient = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0 > 24 ? 86 : 66
        }
        textView.frame = CGRect(x: 24, y: self.view.frame.height - coefficient, width: self.view.frame.width - 48, height: 56)
        tableViewBottom.constant = 66
        self.view.addSubview(textView)
        textView.textView.delegate = self
        textView.sendButtonDelegate = self
    }
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(UINib(nibName: "TicketDetailsMessageCell", bundle: nil), forCellReuseIdentifier: "TicketDetailsMessageCell")
    }

    @IBAction func closeButtonDidPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension TicketDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = TicketDatailsHeader.instanceFromNib()
        header.fillHeaderLabels(with: dataSource)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 190
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.comments.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailsMessageCell", for: indexPath) as? TicketDetailsMessageCell
        cell?.fillCell(with: dataSource?.comments[indexPath.row])
        return cell ?? UITableViewCell()
    }
    
}

extension TicketDetailsViewController: UITextViewDelegate, SendButtonPressedDelegate {
    
    func sendButtonDidPressed() {
        print("message was sent")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let customTextView = textView as? CustomTextView else { return }
        customTextView.textViewDidChange()
    }
}
