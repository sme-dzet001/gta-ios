//
//  MyTicketsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 19.11.2020.
//

import UIKit
import PanModal

class MyTicketsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var errorLabel: UILabel = UILabel()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    private var myTicketsData: [GSDTickets]? {
        return dataProvider?.myTickets
    }
    var dataProvider: HelpDeskDataProvider?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addErrorLabel(errorLabel, isGSD: true)
        getMyTickets()
    }
    
    private func getMyTickets() {
        startAnimation()
        dataProvider?.getMyTickets(completion: {[weak self] (errorCode, error, dataWasChanged) in
            DispatchQueue.main.async {
                self?.stopAnimation()
                if error == nil && errorCode == 200 {
                    self?.errorLabel.isHidden = true
                    //self?.tableView.isHidden = false
                    if dataWasChanged { self?.tableView.reloadData() }
                } else {
                    if let myTickets = self?.myTicketsData, myTickets.isEmpty {
                        self?.tableView.reloadData()
                    }
                    self?.errorLabel.isHidden = !(self?.myTicketsData?.isEmpty ?? true)
                    self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                }
            }
        })
    }
    
    private func startAnimation() {
        guard myTicketsData == nil || (myTicketsData ?? []).isEmpty else { return }
        self.errorLabel.isHidden = true
        self.tableView.alpha = 0
        self.addLoadingIndicator(activityIndicator)
        self.activityIndicator.startAnimating()
        self.addLoadingIndicator(activityIndicator, isGSD: true)
    }
    
    private func stopAnimation() {
        if !(myTicketsData ?? []).isEmpty {
            self.tableView.alpha = 1
        }
        self.activityIndicator.stopAnimating()
        self.activityIndicator.removeFromSuperview()
    }
    
    private func setUpNavigationItem() {
        navigationItem.title = "My Tickets"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back_arrow"), style: .plain, target: self, action: #selector(backPressed))
        navigationItem.leftBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
       // navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search_icon"), style: .plain, target: self, action: #selector(searchPressed))
        navigationItem.rightBarButtonItem?.customView?.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
    private func setUpTableView() {
        //tableView.rowHeight = 260//300//158
        tableView.register(UINib(nibName: "TicketCell", bundle: nil), forCellReuseIdentifier: "TicketCell")
    }
    
    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func searchPressed() {
        // not implemented yet
    }
    
}

extension MyTicketsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myTicketsData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TicketCell", for: indexPath) as? TicketCell {
            cell.setUpCell(with: myTicketsData?[indexPath.row], hideSeparator: indexPath.row == (myTicketsData?.count ?? 0) - 1)
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if myTicketsData?[indexPath.row].status == .closed {
            return 260
        }
        return 200
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MyTicketsHeader.instanceFromNib()
        header.delegate = self
        header.setUpAction()
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (myTicketsData?.count ?? 0) > indexPath.row else { return }
//        switch indexPath.row {
//        case 2, 5:
//            let ticketDetailsVC = SecondTicketDetailsViewController()
//            ticketDetailsVC.dataSource = myTicketsData[indexPath.row]
//            if !UIDevice.current.iPhone5_se {
//                let coefficient: CGFloat = UIDevice.current.iPhone7_8 ? 1.3 : 1.5
//                ticketDetailsVC.initialHeight = PanModalHeight.contentHeight(self.view.frame.height / coefficient)
//            }
//            presentPanModal(ticketDetailsVC)
//        default:
            let ticketDetailsVC = TicketDetailsViewController()
        ticketDetailsVC.dataSource = myTicketsData?[indexPath.row]
        ticketDetailsVC.dataProvider = dataProvider
            //ticketDetailsVC.dataSource = myTicketsData[indexPath.row]
//            if !UIDevice.current.iPhone5_se {
//                //let coefficient: CGFloat = UIDevice.current.iPhone7_8 ? 1.3 : 1.5
//                ticketDetailsVC.initialHeight = .maxHeight// PanModalHeight.contentHeight(self.view.frame.height / coefficient)
//            }
            presentPanModal(ticketDetailsVC)
        //}
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 88
    }
    
}

extension MyTicketsViewController: CreateTicketDelegate {
    func createTicketDidPressed() {
        let newTicketVC = NewTicketViewController()
        newTicketVC.delegate = self
        self.presentPanModal(newTicketVC)
    }
}

extension MyTicketsViewController: SendEmailDelegate {
    func sendEmail(withTitle subject: String, withText body: String, to recipient: String) {
        
    }
    
}

enum TicketStatus {
    case new
    case open
    case closed
    case none
}
