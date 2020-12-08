//
//  HelpDeskDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

class HelpDeskDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    private(set) var quickHelpData = [QuickHelpRow]()
    private(set) var teamContactsData = [TeamContactsRow]()
    
    var quickHelpDataIsEmpty: Bool {
        return quickHelpData.isEmpty
    }
    
    var teamContactsDataIsEmpty: Bool {
        return teamContactsData.isEmpty
    }
    
    func getHelpDeskData(completion: ((_ reportData: HelpDeskResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.serviceDesk.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdProfile.rawValue }?.generationNumber
            if let _ = generationNumber {
                self?.apiManager.getHelpDeskData(for: generationNumber!, completion: completion)
            } else {
                completion?(nil, errorCode, error)
            }
        }
    }
    
    func formQuickHelpAnswerBody(from base64EncodedText: String?) -> String? {
        guard let encodedText = base64EncodedText else { return nil }
        guard let data = Data(base64Encoded: encodedText) else { return encodedText }
        return String(data: data, encoding: .utf8)
    }
    
    func getQuickHelpData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.serviceDesk.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.gsdQuickHelp.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdQuickHelp.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getQuickHelp(generationNumber: generationNumber) { (quickHelpResponse, errorCode, error) in
                    if let quickHelpResponse = quickHelpResponse {
                        self?.fillQuickHelpData(with: quickHelpResponse)
                    }
                    completion?(errorCode, error)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillQuickHelpData(with quickHelpResponse: QuickHelpResponse) {
        quickHelpData = quickHelpResponse.data?.rows ?? []
    }
    
    func getTeamContactsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.serviceDesk.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.gsdTeamContacts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdTeamContacts.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getTeamContacts(generationNumber: generationNumber) { (teamContactsResponse, errorCode, error) in
                    if let teamContactsResponse = teamContactsResponse {
                        self?.fillTeamContactsData(with: teamContactsResponse)
                    }
                    completion?(errorCode, error)
                }
            } else {
                completion?(errorCode, error)
            }
        }
    }
    
    private func fillTeamContactsData(with teamContactsResponse: TeamContactsResponse) {
        teamContactsData = teamContactsResponse.data?.rows ?? []
    }
    
    func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func getContactImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        apiManager.loadImageData(from: url, completion: completion)
    }
    
}
