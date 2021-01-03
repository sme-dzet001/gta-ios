//
//  HelpDeskDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

class HelpDeskDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    
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
                self?.getCachedResponse(for: .getHelpDeskData) {[weak self] (data, error) in
                    if let _ = data {
                        self?.processHelpDeskData(data: data, reportDataResponse: reportData, error: error, errorCode: errorCode, completion: completion)
                    }
                }
                self?.apiManager.getHelpDeskData(for: generationNumber!) { (data, errorCode, error) in
                    self?.cacheData(data, path: .getHelpDeskData)
                    self?.processHelpDeskData(data: data, reportDataResponse: reportData, error: error, errorCode: errorCode, completion: completion)
                }
            } else {
                completion?(nil, errorCode, error)
            }
        }
    }
    
    private func processHelpDeskData(data: Data?, reportDataResponse: ReportDataResponse?, error: Error?, errorCode: Int, completion: ((_ respone: HelpDeskResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var helpDeskResponse: HelpDeskResponse?
        var retErr = error
        if let responseData = data {
            do {
                helpDeskResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = error
            }
        }
        let indexes = getDataIndexes(columns: helpDeskResponse?.meta.widgetsDataSource?.params?.columns)
        helpDeskResponse?.indexes = indexes
        completion?(helpDeskResponse, errorCode, retErr)
    }
    
    func formQuickHelpAnswerBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
        guard let encodedText = base64EncodedText, let data = Data(base64Encoded: encodedText), let htmlBodyString = String(data: data, encoding: .utf8), let htmlAttrString = htmlBodyString.htmlToAttributedString else { return nil }
        
        let res = NSMutableAttributedString(attributedString: htmlAttrString)
        
        guard let mailRegex = try? NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: []) else { return res }
        
        let wholeRange = NSRange(res.string.startIndex..., in: res.string)
        let matches = (mailRegex.matches(in: res.string, options: [], range: wholeRange))
        for match in matches {
            guard let mailLinkRange = Range(match.range, in: res.string) else { continue }
            let mailLinkStr = res.string[mailLinkRange]
            if let linkUrl = URL(string: "mailto:\(mailLinkStr)") {
                res.addAttribute(.link, value: linkUrl, range: match.range)
            }
        }
        return res
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
            fillQuickHelpData(with: quickHelpResponse)
        }
        completion?(errorCode, retErr)
    }
    
    private func processQuickHelpSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdQuickHelp.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdQuickHelp.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            getCachedResponse(for: .getQuickHelpData) {[weak self] (data, error) in
                if let _ = data {
                    self?.processQuickHelp(reportData, data, 200, error, completion)
                }
            }
            apiManager.getQuickHelp(generationNumber: generationNumber, completion: { [weak self] (quickHelpResponse, errorCode, error) in
                self?.cacheData(quickHelpResponse, path: .getQuickHelpData)
                self?.processQuickHelp(reportData, quickHelpResponse, errorCode, error, completion)
            })

        } else {
            completion?(errorCode, error)
        }
    }
    
    func getQuickHelpData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            if let _ = data {
                self?.processQuickHelpSectionReport(data, 200, error, false, completion)
            }
        }
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processQuickHelpSectionReport(reportResponse, errorCode, error, false, completion)
        })
    }
    
    private func fillQuickHelpData(with quickHelpResponse: QuickHelpResponse) {
        let indexes = getDataIndexes(columns: quickHelpResponse.meta.widgetsDataSource?.params?.columns)
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
            fillTeamContactsData(with: teamContactsResponse)
        }
        completion?(errorCode, retErr)
    }
    
    private func processTeamContactsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdTeamContacts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdTeamContacts.rawValue }?.generationNumber
        if let generationNumber = generationNumber {
            getCachedResponse(for: .getTeamContactsData) {[weak self] (data, error) in
                if let _ = data {
                    self?.processTeamContacts(reportData, data, 200, error, completion)
                }
            }
            apiManager.getTeamContacts(generationNumber: generationNumber, completion: { [weak self] (teamContactsResponse, errorCode, error) in
                self?.cacheData(teamContactsResponse, path: .getTeamContactsData)
                self?.processTeamContacts(reportData, teamContactsResponse, errorCode, error, completion)
            })
        } else {
            completion?(errorCode, error)
        }
    }
    
    func getTeamContactsData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            if let _ = data {
                self?.processTeamContactsSectionReport(data, 200, error, completion)
            }
        }
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            self?.processTeamContactsSectionReport(reportResponse, errorCode, error, completion)
        })
    }
    
    private func fillTeamContactsData(with teamContactsResponse: TeamContactsResponse) {
        let indexes = getDataIndexes(columns: teamContactsResponse.meta.widgetsDataSource?.params?.columns)
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
    
    private func cacheData(_ data: Data?, path: CacheManager.path) {
        guard let _ = data else { return }
        cacheManager.cacheResponse(responseData: data!, requestURI: path.endpoint) { (error) in
            if let error = error {
                print("Function: \(#function), line: \(#line), message: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCachedResponse(for path: CacheManager.path, completion: @escaping ((_ data: Data?, _ error: Error?) -> Void)) {
        cacheManager.getCachedResponse(requestURI: path.endpoint, completion: completion)
    }
    
}
