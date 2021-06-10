//
//  MyTicketsViewController.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 19.11.2020.
//

import UIKit
import PanModal
import MessageUI

class MyTicketsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createTicketView: UIView!
    
    private var errorLabel: UILabel = UILabel()
    private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var dataProvider: HelpDeskDataProvider?
    weak var sortFilterDelegate: SortFilterDelegate?
    private var filterType: FilterType = .all
    private var sortingType: SortType?
    
    private var myTicketsData: [GSDTickets]? {
        return generateDataSource()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItem()
        setUpTableView()
        setUpCreateTicketAction()
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
                    if (error as? ResponseError) == .noDataAvailable {
                        self?.errorLabel.text = "No tickets in the last 90 days"
                    } else {
                        self?.errorLabel.text = (error as? ResponseError)?.localizedDescription ?? "Oops, something went wrong"
                    }
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
        if (myTicketsData ?? []).isEmpty {
            self.tableView.reloadData()
        }
        self.tableView.alpha = 1
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
    
    private func setUpCreateTicketAction() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(createTicketDidPressed))
        tap.cancelsTouchesInView = false
        self.createTicketView?.addGestureRecognizer(tap)
    }
    
    @objc private func createTicketDidPressed() {
        guard let lastUserEmail = UserDefaults.standard.string(forKey: "lastUserEmail") else { return }
        let newTicketVC = NewTicketViewController()
        newTicketVC.delegate = self
        newTicketVC.appUserEmail = lastUserEmail
        self.presentPanModal(newTicketVC)
    }
    
    @objc private func sortDidPressed() {
        sortFilterDelegate?.sortDidPressed()
    }
    
    @objc private func filterDidPressed() {
        sortFilterDelegate?.filterDidPressed()
    }
    
    private func generateDataSource() -> [GSDTickets]? {
        var dataSource = dataProvider?.myTickets
        if let sorting = sortingType {
            switch sorting {
            case .newToOld:
                dataSource = dataSource?.sorted(by: {$0.openDateTimeInterval > $1.openDateTimeInterval})
            case .oldToNew:
                dataSource = dataSource?.sorted(by: {$0.openDateTimeInterval < $1.openDateTimeInterval})
            }
        }
        switch filterType {
        case .closed:
            dataSource = dataSource?.filter({$0.status == .closed})
        case .new:
            dataSource = dataSource?.filter({$0.status == .new})
        default:
            return dataSource
        }
        return dataSource
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
}

extension MyTicketsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myTicketsData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard (myTicketsData?.count ?? 0) > indexPath.row else { return UITableViewCell() }
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
        let header = MyTicketsFilterHeader.instanceFromNib()
        header.filterView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(filterDidPressed)))
        header.sortView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sortDidPressed)))
        sortFilterDelegate = header
        header.setUpTextFields()
        header.selectionDelegate = self
        return header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard (myTicketsData?.count ?? 0) > indexPath.row else { return }
        let ticketDetailsVC = TicketDetailsViewController()
        ticketDetailsVC.dataSource = myTicketsData?[indexPath.row]
        ticketDetailsVC.dataProvider = dataProvider
        presentPanModal(ticketDetailsVC)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
    
}

extension MyTicketsViewController: SendEmailDelegate {
    func sendEmail(withTitle subject: String, withText body: String, to recipient: String) {
        if MFMailComposeViewController.canSendMail() {
            if !Reachability.isConnectedToNetwork() {
                displayError(errorMessage: "Please verify your network connection and try again. If the error persists please try again later", title: nil, onClose: nil)
                return
            }
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            if let lastUserEmail = UserDefaults.standard.string(forKey: "lastUserEmail") {
                mail.setPreferredSendingEmailAddress(lastUserEmail)
            }
            mail.setToRecipients([Constants.ticketSupportEmail])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else {
            displayError(errorMessage: "Configure your mail in iOS mail app to use this feature", title: nil)
        }
    }
}

extension MyTicketsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

extension MyTicketsViewController: FilterSortingSelectionDelegate {
    func filterTypeDidSelect(_ selectedType: FilterType) {
        filterType = selectedType
        tableView.reloadData()
    }
    
    func sortingTypeDidSelect(_ selectedType: SortType) {
        sortingType = selectedType
        tableView.reloadData()
    }
}

enum TicketStatus {
    case new
    case open
    case closed
    case none
}

protocol SortFilterDelegate: AnyObject {
    func sortDidPressed()
    func filterDidPressed()
}
