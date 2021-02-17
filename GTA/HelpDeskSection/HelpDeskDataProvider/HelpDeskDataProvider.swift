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
    private var imageCacheManager: ImageCacheManager = ImageCacheManager()
    
    private(set) var quickHelpData = [QuickHelpRow]()
    private(set) var teamContactsData = [TeamContactsRow]()
    private var refreshTimer: Timer?
    private var cachedReportData: Data?
    
    var quickHelpDataIsEmpty: Bool {
        return quickHelpData.isEmpty
    }
    
    var teamContactsDataIsEmpty: Bool {
        return teamContactsData.isEmpty
    }
    
    func getGSDStatus(completion: ((_ reportData: GSDStatus?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getSectionReport() { [weak self] (reportResponse, errorCode, error, isFromCache) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdStatus.rawValue }?.generationNumber
            if let _ = generationNumber {
                if isFromCache {
                    self?.getCachedResponse(for: .getGSDStatus) {[weak self] (data, error) in
                        if let _ = data {
                            self?.processGSDStatus(data: data, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
                        }
                    }
                    return
                }
                self?.apiManager.getGSDStatus(generationNumber: generationNumber!, completion: { (data, errorCode, error) in
                    let dataWithStatus = self?.addStatusRequest(to: data)
                    self?.cacheData(dataWithStatus, path: .getGSDStatus)
                    self?.processGSDStatus(data: dataWithStatus, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
                })
            } else {
                let retError = ResponseError.serverError
                completion?(nil, errorCode, retError, isFromCache)
            }
        }
    }
    
    func getHelpDeskData(completion: ((_ reportData: HelpDeskResponse?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getSectionReport() { [weak self] (reportResponse, errorCode, error, isFromCache) in
            let reportData = self?.parseSectionReport(data: reportResponse)
            let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdProfile.rawValue }?.generationNumber
            if let _ = generationNumber {
                if isFromCache {
                    self?.getCachedResponse(for: .getHelpDeskData) {[weak self] (data, error) in
                        if let _ = data {
                            self?.processHelpDeskData(data: data, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
                        }
                    }
                    return
                }
                self?.apiManager.getHelpDeskData(for: generationNumber!) { (data, errorCode, error) in
                    self?.cacheData(data, path: .getHelpDeskData)
                    self?.processHelpDeskData(data: data, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
                }
            } else {
                let retError = ResponseError.serverError
                completion?(nil, errorCode, retError, isFromCache)
            }
        }
    }
    
    private func getSectionReport(completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            if let _ = data {
                self?.cachedReportData = data
                completion?(data, 200, cachedError, true)
            }
            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                self?.cacheData(reportResponse, path: .getSectionReport)
                completion?(reportResponse, errorCode, error, false)
            })
        }
    }
    
    func activateStatusRefresh(completion: @escaping ((_ isNeedToRefreshStatus: Bool) -> Void)) {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) {[weak self] (_) in
            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                if let cahcedReport = self?.parseSectionReport(data: self?.cachedReportData), let serverReport = self?.parseSectionReport(data: reportResponse) {
                    completion(serverReport != cahcedReport)
                } else {
                    completion(true)
                }
            })
        }
    }
    
    func invalidateStatusRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func processHelpDeskData(data: Data?, reportDataResponse: ReportDataResponse?, _ isFromCache: Bool, error: Error?, errorCode: Int, completion: ((_ respone: HelpDeskResponse?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var helpDeskResponse: HelpDeskResponse?
        var retErr = error
        if let responseData = data {
            do {
                helpDeskResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        let indexes = getDataIndexes(columns: helpDeskResponse?.meta.widgetsDataSource?.params?.columns)
        helpDeskResponse?.indexes = indexes
        if let helpDeskResponse = helpDeskResponse {
            var missingHelpDeskFields = [String]()
            if (helpDeskResponse.serviceDeskPhoneNumber ?? "").isEmpty {
                missingHelpDeskFields.append("phoneNumber")
            }
            if (helpDeskResponse.serviceDeskEmail ?? "").isEmpty {
                missingHelpDeskFields.append("email")
            }
            if (helpDeskResponse.teamsChatLink ?? "").isEmpty {
                missingHelpDeskFields.append("teamsChat")
            }
            if !missingHelpDeskFields.isEmpty {
                retErr = ResponseError.missingFieldError(missingFields: missingHelpDeskFields)
            }
        }
        completion?(helpDeskResponse, errorCode, retErr, isFromCache)
    }
    
    private func processGSDStatus(data: Data?, reportDataResponse: ReportDataResponse?, _ isFromCache: Bool, error: Error?, errorCode: Int, completion: ((_ respone: GSDStatus?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var statusResponse: GSDStatus?
        var retErr = error
        if let responseData = data {
            do {
                statusResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let requestDate = statusResponse?.data?.requestDate, isNeedToRemoveResponseForDate(requestDate) {
            cacheManager.removeCachedData(for: CacheManager.path.getMyAppsData.endpoint)
            return
        }
        let indexes = getDataIndexes(columns: statusResponse?.meta?.widgetsDataSource?.params?.columns)
        statusResponse?.indexes = indexes
        if (error != nil || statusResponse == nil) && isFromCache {
            return
        }
        completion?(statusResponse, errorCode, retErr, isFromCache)
    }
    
    private func addStatusRequest(to data: Data?) -> Data? {
        guard let _ = data, var stringData = String(data: data!, encoding: .utf8) else { return data }
        if let index = stringData.lastIndex(where: {$0 == "]"}) {
            let nextIndex = stringData.index(after: index)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = String.comapreDateFormat
            let dateString = dateFormatter.string(from: Date())
            stringData.insert(contentsOf: ", \"requestDate\" : \"\(dateString)\"", at: nextIndex)
            return stringData.data(using: .utf8)
        }
        return data
    }
    
    private func isNeedToRemoveResponseForDate(_ date: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String.comapreDateFormat
        guard var comparingDate = dateFormatter.date(from:date) else { return true }
        comparingDate.addTimeInterval(900)
        return Date() >= comparingDate
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
    
    /// Returns true if data was updated, otherwise false
    private func checkQuickHelpDataForUpdates(previousData: [QuickHelpRow]) -> Bool {
        guard previousData.count == quickHelpData.count else { return true }
        var dataWasUpdated = false
        for i in 0..<quickHelpData.count {
            if quickHelpData[i] != previousData[i] {
                dataWasUpdated = true
                break
            }
        }
        return dataWasUpdated
    }
    
    private func processQuickHelp(_ reportData: ReportDataResponse?, _ quickHelpResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var quickHelpDataResponse: QuickHelpResponse?
        var retErr = error
        if let responseData = quickHelpResponse {
            do {
                quickHelpDataResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        let previousData = quickHelpData
        if let quickHelpResponse = quickHelpDataResponse {
            fillQuickHelpData(with: quickHelpResponse)
            if (quickHelpResponse.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        let dataWasChanged = checkQuickHelpDataForUpdates(previousData: previousData)
        completion?(dataWasChanged, errorCode, retErr)
    }
    
    private func processQuickHelpSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
            let retError = ResponseError.serverError
            completion?(true, errorCode, retError)
        }
    }
    
    func getQuickHelpData(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
                retErr = ResponseError.parsingError
            }
        }
        if let teamContactsResponse = teamContactsDataResponse {
            fillTeamContactsData(with: teamContactsResponse)
            if (teamContactsResponse.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
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
            let retError = ResponseError.serverError
            completion?(errorCode, retError)
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
        teamContactsData.removeAll { $0.contactName == nil || ($0.contactName ?? "").isEmpty || $0.contactEmail == nil || ($0.contactEmail ?? "").isEmpty }
    }
    
    func formImageURL(from imagePath: String?) -> String? {
        guard let imagePath = imagePath, !imagePath.isEmpty else { return nil }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func getImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        if let cachedResponse = imageCacheManager.getCacheResponse(for: url) {
            if let responseStr = String(data: cachedResponse, encoding: .utf8), responseStr.contains("Not Found") {
                completion(nil, nil)
            } else {
                completion(cachedResponse, nil)
            }
            return
        } else {
            apiManager.loadImageData(from: url) { (data, response, error) in
                // checking that response status code == 200, else return no data
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                } else {
                    self.imageCacheManager.storeCacheResponse(response, data: data)
                    DispatchQueue.main.async {
                        completion(data, error)
                    }
                }
            }
        }
    }
    
//    func getServiceDeskImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
//        apiManager.loadImageData(from: url, completion: completion)
//    }
    
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
