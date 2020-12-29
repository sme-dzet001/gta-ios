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
        apiManager.getSectionReport() { [weak self] (reportResponse, errorCode, error) in
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
                    let indexes = self?.getDataIndexes(columns: reportData?.meta.widgetsDataSource?.gsdProfile?.columns) ?? [:]
                    reportDataResponse?.indexes = indexes
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
    
    private func processQuickHelp(_ reportData: ReportDataResponse?, _ quickHelpResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
            fillQuickHelpData(with: quickHelpResponse, indexes: (getDataIndexes(columns: reportData?.meta.widgetsDataSource?.gsdQuickHelp?.columns)))
        }
        completion?(errorCode, retErr)
    }
    
    private func processSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdQuickHelp.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdQuickHelp.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            apiManager.getQuickHelp(generationNumber: generationNumber, cachedDataCallback: fromCache ? { [weak self] (quickHelpResponse, errorCode, error) in
                self?.processQuickHelp(reportData, quickHelpResponse, errorCode, error, completion)
            } : nil, completion: fromCache ? nil : { [weak self] (quickHelpResponse, errorCode, error) in
                self?.processQuickHelp(reportData, quickHelpResponse, errorCode, error, completion)
            })

        } else {
            completion?(errorCode, error)
        }
    }
    
    func getQuickHelpData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(cachedDataCallback: { [weak self] (reportResponse, errorCode, error) in
            self?.processSectionReport(reportResponse, errorCode, error, true, completion)
        }, completion: { [weak self] (reportResponse, errorCode, error) in
            self?.processSectionReport(reportResponse, errorCode, error, false, completion)
        })
    }
    
    private func fillQuickHelpData(with quickHelpResponse: QuickHelpResponse, indexes: [String : Int]) {
        var response: QuickHelpResponse = quickHelpResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        quickHelpData = response.data?.rows ?? []
    }
    
    private func processTeamContacts(_ reportData: ReportDataResponse?, _ teamContactsResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
            fillTeamContactsData(with: teamContactsResponse, indexes: getDataIndexes(columns: reportData?.meta.widgetsDataSource?.gsdTeamContacts?.columns))
        }
        completion?(errorCode, retErr)
    }
    
    private func processTeamContactsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdTeamContacts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdTeamContacts.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            apiManager.getTeamContacts(generationNumber: generationNumber, cachedDataCallback: fromCache ? { [weak self] (teamContactsResponse, errorCode, error) in
                self?.processTeamContacts(reportData, teamContactsResponse, errorCode, error)
            } : nil, completion: fromCache ? nil : { [weak self] (teamContactsResponse, errorCode, error) in
                self?.processTeamContacts(reportData, teamContactsResponse, errorCode, error)
            })
        } else {
            completion?(errorCode, error)
        }
    }
    
    func getTeamContactsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(cachedDataCallback: { [weak self] (reportResponse, errorCode, error) in
            self?.processTeamContactsSectionReport(reportResponse, errorCode, error, true, completion)
        }, completion: { [weak self] (reportResponse, errorCode, error) in
            self?.processTeamContactsSectionReport(reportResponse, errorCode, error, false, completion)
        })
    }
    
    private func fillTeamContactsData(with teamContactsResponse: TeamContactsResponse, indexes: [String : Int]) {
        var response: TeamContactsResponse = teamContactsResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        teamContactsData = response.data?.rows ?? []
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
    
    private func getDataIndexes(columns: [ColumnName]?) -> [String : Int] {
        var indexes: [String : Int] = [:]
        guard let columns = columns else { return indexes}
        for (index, column) in columns.enumerated() {
            if let name = column.name {
                indexes[name] = index
            }
        }
        return indexes
    }
    
}
