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
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdProfile.rawValue }?.generationNumber
            if let _ = generationNumber {
                self?.apiManager.getHelpDeskData(for: generationNumber!) { (data, errorCode, error) in
                    var reportDataResponse: HelpDeskResponse?
                    var retErr = error
                    if let responseData = data {
                        do {
                            reportDataResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    completion?(reportDataResponse, errorCode, retErr)
                }
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
    
    private func getQuickHelp(generationNumber: Int, fromCache: Bool, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        
    }
    
    func getQuickHelpData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.serviceDesk.rawValue, completion: { [weak self] (reportResponse, errorCode, error) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdQuickHelp.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdQuickHelp.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getQuickHelp(generationNumber: generationNumber, completion: { (quickHelpResponse, errorCode, error) in
                    var quickHelpDataResponse: QuickHelpResponse?
                    var retErr = error
                    if let responseData = quickHelpResponse {
                        do {
                            quickHelpDataResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    if let quickHelpResponse = quickHelpDataResponse {
                        self?.fillQuickHelpData(with: quickHelpResponse)
                    }
                    completion?(errorCode, retErr)
                })
            } else {
                completion?(errorCode, error)
            }
        })
    }
    
    private func fillQuickHelpData(with quickHelpResponse: QuickHelpResponse) {
        quickHelpData = quickHelpResponse.data?.rows ?? []
    }
    
    func getTeamContactsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.serviceDesk.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdTeamContacts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdTeamContacts.rawValue }?.generationNumber
            if let generationNumber = generationNumber {
                self?.apiManager.getTeamContacts(generationNumber: generationNumber) { (teamContactsResponse, errorCode, error) in
                    var teamContactsDataResponse: TeamContactsResponse?
                    var retErr = error
                    if let responseData = teamContactsResponse {
                        do {
                            teamContactsDataResponse = try DataParser.parse(data: responseData)
                        } catch {
                            retErr = error
                        }
                    }
                    if let teamContactsResponse = teamContactsDataResponse {
                        self?.fillTeamContactsData(with: teamContactsResponse)
                    }
                    completion?(errorCode, retErr)
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
    
    private func parseSectionReport(data: Data?) -> ReportDataResponse? {
        var reportDataResponse: ReportDataResponse?
        if let responseData = data {
            do {
                reportDataResponse = try DataParser.parse(data: responseData)
            } catch {
                print("Function: \(#function), line: \(#line), message: \(error.localizedDescription)")
            }
        }
        return reportDataResponse
    }
    
}
