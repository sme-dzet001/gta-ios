//
//  SecondTicketDetailsViewController.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 20.11.2020.
//

import UIKit
import PanModal

class SecondTicketDetailsViewController: UIViewController, PanModalPresentable {
    
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
        addDetailsView()
    }
    
    private func addDetailsView() {
        let detailsView = TicketDatailsHeader.instanceFromNib()
        detailsView.fillHeaderLabels(with: dataSource)
        detailsView.frame = CGRect(x: 0, y: 70, width: self.view.frame.width, height: 190)
        view.addSubview(detailsView)
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

extension SecondTicketDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if dataSource?.status == .closed {
            return nil
        }
        let header = SecondSendMessageView.instanceFromNib()
        header.setUpView()
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource?.status == .closed {
            return 0
        }
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

extension SecondTicketDetailsViewController: UITextViewDelegate, SendButtonPressedDelegate {
    
    func sendButtonDidPressed() {
        print("message was sent")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let customTextView = textView as? CustomTextView else { return }
        customTextView.textViewDidChange()
    }
}
