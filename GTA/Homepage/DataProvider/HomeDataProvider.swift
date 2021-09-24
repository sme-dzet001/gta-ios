//
//  HomeDataProvider.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 02.12.2020.
//

import Foundation

class HomeDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    private(set) var userLocationManager: UserLocationManager = UserLocationManager()
    
    private(set) var GTTeamContactsData: GTTeamResponse?
    private(set) var globalAlertsData: GlobalAlertRow?
    private(set) var productionGlobalAlertsData: ProductionAlertsRow?
    private(set) var activeProductionGlobalAlert: ProductionAlertsRow?
    private(set) var newsFeedData: [NewsFeedRow] = []
    private(set) var specialAlertsData: [NewsFeedRow] = []
    private(set) var getNewsFeedInProgress: Bool = false
    private var processProductionAlertsQueue = DispatchQueue(label: "HomeTabProcessProductionAlertsQueue", qos: .userInteractive)
    
    var forceUpdateAlertDetails: Bool = false
    
    var allNewsFeedData: [NewsFeedRow] = []
    
    func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func formNewsBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
        guard let encodedText = base64EncodedText, let data = Data(base64Encoded: encodedText), let htmlBodyString = String(data: data, encoding: .utf8), let htmlAttrString = htmlBodyString.htmlToAttributedString else { return nil }
        
        let res = NSMutableAttributedString(attributedString: htmlAttrString)
        res.trimCharactersInSet(.whitespacesAndNewlines)
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
    
    func formatDateString(dateString: String?, initialDateFormat: String) -> String? {
        guard let dateString = dateString else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = initialDateFormat
        let date: Date
        if let formattedDate = dateFormatter.date(from: dateString) {
            date = formattedDate
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let formattedDate = dateFormatter.date(from: dateString) {
                date = formattedDate
            } else {
                return dateString
            }
        }
        dateFormatter.dateFormat = "E MMM d'\(date.daySuffix())', yyyy"
        let formattedDateString = dateFormatter.string(from: date)
        return formattedDateString
    }
    
    // MARK: - News feed related methods
    
    func getNewsFeedData(completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getNewsFeedInProgress = true
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processNewsFeedSectionReport(data, code, cachedError, true, { (_, dataWasChanged, code, error) in
                if error == nil {
                    self?.getNewsFeedInProgress = false
                    completion?(true, dataWasChanged, code, cachedError)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        self?.getNewsFeedInProgress = false
                        completion?(false, false, errorCode, ResponseError.generate(error: error))
                    } else {
                        self?.processNewsFeedSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func processNewsFeedSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.newsFeed.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getNewsFeed) {[weak self] (data, error) in
                    self?.processNewsFeedData(reportData, data, isFromCache, 200, error, completion)
                }
                return
            }
            apiManager.getNewsFeedData(generationNumber: generationNumber) { [weak self] (response, errorCode, error) in
                if let _ = error {
                    self?.getNewsFeedInProgress = false
                    completion?(false, true, 0, ResponseError.generate(error: error))
                    return
                }
                self?.cacheData(response, path: .getNewsFeed)
                self?.processNewsFeedData(reportData, response, isFromCache, errorCode, error, completion)
            }
        } else {
            if !isFromCache { self.getNewsFeedInProgress = false }
            if error != nil || generationNumber == 0 {
                completion?(isFromCache, false, 0, generationNumber == 0 ? ResponseError.noDataAvailable: ResponseError.generate(error: error))
                return
            }
            completion?(isFromCache, false, 0, error)
        }
    }
    
    private func processNewsFeedData(_ reportData: ReportDataResponse?, _ response: Data?, _ isFromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var newsFeedResponse: NewsFeedResponse?
        var retErr = error
        if let responseData = response {
            do {
                newsFeedResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        var dataWasChanged: Bool = false
        if let _ = newsFeedResponse {
            dataWasChanged = fillNewsFeedData(with: newsFeedResponse!)
        }
        if !isFromCache { self.getNewsFeedInProgress = false }
        completion?(isFromCache, dataWasChanged, errorCode, retErr)
    }
    
    private func fillNewsFeedData(with data: NewsFeedResponse) -> Bool {
        let indexes = getDataIndexes(columns: data.meta?.widgetsDataSource?.params?.columns)
        var response: NewsFeedResponse = data
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index]?.indexes = indexes
            }
        }
        let rows = response.data?.rows?.compactMap({$0})
        var allNews = rows?.filter({$0.isPostDateExist == true}).sorted(by: {$1.newsDate! < $0.newsDate!}) ?? []
        let newsWithoutDate = rows?.filter({$0.isPostDateExist == false}).sorted(by: {($1.articleId ?? 0) < ($0.articleId ?? 0)}) ?? []
        allNews.append(contentsOf: newsWithoutDate)
        let dataWasChanged = allNews != allNewsFeedData
        allNewsFeedData = allNews
        newsFeedData = allNews.filter({$0.category == .news})
        specialAlertsData = allNews.filter({$0.category == .specialAlerts})
        return dataWasChanged
    }
    
    // MARK: - Global Alerts related methods
    
    func getGlobalAlerts(completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processGlobalAlertsSectionReport(data, code, cachedError, true, { (_, dataWasChanged, code, error) in
                if error == nil {
                    completion?(true, dataWasChanged, code, cachedError)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, false, errorCode, ResponseError.generate(error: error))
                    } else {
                        self?.processGlobalAlertsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    func getGlobalAlertsIgnoringCache(completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            if let _ = error {
                completion?(false, false, errorCode, ResponseError.serverError)
            } else {
                self?.processGlobalAlertsSectionReport(reportResponse, errorCode, error, false, completion)
            }
        })
    }
    
    private func processGlobalAlertsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalAlerts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalAlerts.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getGlobalOutage) {[weak self] (data, error) in
                    self?.processGlobalAlerts(reportData, data, isFromCache, 200, error, completion)
                }
                return
            }
            apiManager.getGlobalAlerts(generationNumber: generationNumber) { [weak self] (response, errorCode, error) in
                if let _ = error {
                    completion?(false, true, 0, ResponseError.generate(error: error))
                    return
                }
                self?.cacheData(response, path: .getGlobalOutage)
                self?.processGlobalAlerts(reportData, response, isFromCache, errorCode, error, completion)
            }
        } else {
            if error != nil || generationNumber == 0 {
                completion?(isFromCache, false, 0, generationNumber == 0 ? ResponseError.noDataAvailable: ResponseError.generate(error: error))
                return
            }
            completion?(isFromCache, false, 0, error)
        }
    }
    
    private func processGlobalAlerts(_ reportData: ReportDataResponse?, _ response: Data?, _ isFromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var alertsResponse: GlobalAlertsResponse?
        var retErr = error
        if let responseData = response {
            do {
                alertsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        var dataWasChanged: Bool = false
        if let _ = alertsResponse {
            dataWasChanged = fillGlobalAlertsData(with: alertsResponse!)
        }
        completion?(isFromCache, dataWasChanged, errorCode, retErr)
    }
    
    private func fillGlobalAlertsData(with response: GlobalAlertsResponse) -> Bool {
        let indexes = getDataIndexes(columns: response.meta?.widgetsDataSource?.params?.columns)
        var response: GlobalAlertsResponse = response
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index]?.indexes = indexes
            }
        }
        
        let rows = response.data?.rows?.compactMap({$0}) ?? []
        var alert = rows.last
        let inProgressAlerts = rows.filter({$0.status == .inProgress})
        let closedAlerts = rows.filter({$0.status == .closed})
        if inProgressAlerts.count >= 1 {
            alert = inProgressAlerts.sorted(by: {$0.startDate.timeIntervalSince1970 > $1.startDate.timeIntervalSince1970}).first
        } else if closedAlerts.count >= 1 {
            alert = closedAlerts.sorted(by: {$0.closeDate.timeIntervalSince1970 > $1.closeDate.timeIntervalSince1970}).first
        }
        let dataWasChanged: Bool = globalAlertsData != alert
        globalAlertsData = alert
        return dataWasChanged
    }
    
    // MARK: - Global Technology Team related methods
    
    func getGTTeamData(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processGTTeamSectionReport(data, code, cachedError, true, { (dataWasChanged, code, error) in
                if error == nil {
                    completion?(dataWasChanged, code, cachedError)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, errorCode, ResponseError.generate(error: error))
                    } else {
                        self?.processGTTeamSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func processGTTeamSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gTTeam.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gTTeam.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getGTTeamData) {[weak self] (data, error) in
                    self?.processGTTeam(reportData, data, 200, error, completion)
                }
                return
            }
            apiManager.getGTTeamData(generationNumber: generationNumber) { [weak self] (response, errorCode, error) in
                if let _ = error {
                    completion?(true, 0, ResponseError.generate(error: error))
                    return
                }
                self?.cacheData(response, path: .getGTTeamData)
                self?.processGTTeam(reportData, response, errorCode, error, completion)
            }
        } else {
            if error != nil || generationNumber == 0 {
                completion?(false, 0, generationNumber == 0 ? ResponseError.noDataAvailable: ResponseError.generate(error: error))
                return
            }
            completion?(false, 0, error)
        }
    }
    
    private func processGTTeam(_ reportData: ReportDataResponse?, _ response: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool,  _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var teamResponse: GTTeamResponse?
        var retErr = error
        if let responseData = response {
            do {
                teamResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        let dataWasChanged = fillGTTeamData(teamResponse)
        completion?(dataWasChanged, errorCode, retErr)
    }
    
    private func fillGTTeamData(_ data: GTTeamResponse?) -> Bool {
        let indexes = getDataIndexes(columns: data?.meta?.widgetsDataSource?.params?.columns)
        var response: GTTeamResponse? = data
        if let rows = response?.data?.rows {
            for (index, _) in rows.enumerated() {
                response?.data?.rows?[index]?.indexes = indexes
            }
        }
        if response == nil && self.GTTeamContactsData != nil {
        } else if response != self.GTTeamContactsData {
            self.GTTeamContactsData = response
            return true
        }
        return false
    }
    
    // MARK: - App Production Alerts related methods
    
    func getProductionAlerts(completion: ((_ errorCode: Int, _ error: Error?, _ count: Int) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleProductionAlertsSectionReport(data, code, cachedError, true, { (code, error, count) in
                if error == nil {
                    completion?(code, cachedError, count)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.serverError, 0)
                    } else {
                        self?.handleProductionAlertsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleProductionAlertsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ count: Int) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.appDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.productionAlerts.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getAppsProductionAlerts) {[weak self] (data, error) in
                    self?.processProductionAlerts(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getAppsProductionAlerts(for: generationNumber!, userEmail: KeychainManager.getUsername() ?? "", completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getAppsProductionAlerts)
                self?.processProductionAlerts(reportData, data, errorCode, error, completion)
            })
        } else {
            let err = error == nil ? ResponseError.commonError : error
            if error != nil || generationNumber == 0 {
                completion?(0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, 0)
                return
            }
            completion?(0, err, 0)
        }
    }
    
    private func processProductionAlerts(_ reportData: ReportDataResponse?, _ myAppsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?, _ count: Int) -> Void)? = nil) {
        processProductionAlertsQueue.async(flags: .barrier) { [weak self] in
            var prodAlertsResponse: ProductionAlertsResponse?
            var retErr = error
            if let responseData = myAppsDataResponse {
                do {
                    prodAlertsResponse = try DataParser.parse(data: responseData)
                } catch {
                    retErr = ResponseError.parsingError
                }
            } else {
                retErr = ResponseError.commonError
            }
            let data = prodAlertsResponse?.data?[KeychainManager.getUsername() ?? ""] ?? [:]
            if data.values.isEmpty {
                retErr = ResponseError.noDataAvailable
            }
            let indexes = self?.getDataIndexes(columns: prodAlertsResponse?.meta?.widgetsDataSource?.params?.columns)
            let count = self?.getProductionAlertsCount(alertData: data, indexes: indexes ?? [:])
            completion?(errorCode, retErr, count ?? 0)
        }
        
    }
    
    private func getProductionAlertsCount(alertData: [String : ProductionAlertsData], indexes: [String : Int]) -> Int {
        var data = alertData
        var count = 0
        for key in data.keys {
            for (index, _) in (data[key]?.data?.rows ?? []).enumerated() {
                data[key]?.data?.rows?[index]?.indexes = indexes
            }
            count += data[key]?.data?.rows?.filter({$0?.isRead == false && $0?.isExpired == false}).count ?? 0
        }
        return count
    }
    
    // MARK: - Global Production Alerts related methods
    
    func getGlobalProductionAlerts(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleGlobalProductionAlertsSectionReport(data, code, cachedError, true, { (dataWasChanged, errorCode, error) in
                if error == nil {
                    completion?(dataWasChanged, errorCode, cachedError)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(true, errorCode, ResponseError.serverError)
                    } else {
                        self?.handleGlobalProductionAlertsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleGlobalProductionAlertsSectionReport(alertID: String? = nil, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        activeProductionGlobalAlert = nil
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalAlerts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalProductionAlerts.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getGlobalProductionAlerts) {[weak self] (data, error) in
                    self?.processGlobalProductionAlerts(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getGlobalProductionAlerts(generationNumber: generationNumber!, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getGlobalProductionAlerts)
                self?.processGlobalProductionAlerts(alertID: alertID, reportData, data, errorCode, error, completion)
            })
        } else {
            let err = error == nil ? ResponseError.commonError : error
            if error != nil || generationNumber == 0 {
                completion?(true, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable)
                return
            }
            completion?(true, 0, err)
        }
    }
    
    private func processGlobalProductionAlerts(alertID: String? = nil, _ reportData: ReportDataResponse?, _ globalProductionAlertsResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var prodAlertsResponse: GlobalProductionAlertsResponse?
        var retErr = error
        if let responseData = globalProductionAlertsResponse {
            do {
                prodAlertsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        if let data = prodAlertsResponse?.data?.rows, data.isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        let dataWasChanged = fillGlobalProductionAlertsData(alertID: alertID, prodAlertsResponse)
        completion?(dataWasChanged, errorCode, retErr)
    }
    
    private func fillGlobalProductionAlertsData(alertID: String? = nil, _ response: GlobalProductionAlertsResponse?) -> Bool {
        let indexes = self.getDataIndexes(columns: response?.meta?.widgetsDataSource?.params?.columns)
        var rows = response?.data?.rows?.compactMap({$0}) ?? []
        for (index, _) in rows.enumerated() {
            rows[index].indexes = indexes
        }
        if let alertID = alertID {
            rows = rows.filter({$0.ticketNumber?.lowercased() == alertID.lowercased()})
        }
        var alert = rows.last
        let activeAlerts = rows.filter({$0.prodAlertsStatus == .activeAlert })
        let closedAlerts = rows.filter({ $0.prodAlertsStatus == .closed && $0.isExpired == false })
        let reminderStateAlerts = rows.filter({$0.prodAlertsStatus == .reminderState})
        let newAlertCreatedAlerts = rows.filter({$0.prodAlertsStatus == .newAlertCreated})
        if activeAlerts.count >= 1 {
            alert = activeAlerts.sorted(by: {$0.startDate.timeIntervalSince1970 > $1.startDate.timeIntervalSince1970}).first
        } else if closedAlerts.count >= 1 {
            alert = closedAlerts.sorted(by: {$0.closeDate.timeIntervalSince1970 > $1.closeDate.timeIntervalSince1970}).first
        } else if reminderStateAlerts.count >= 1 {
            alert = reminderStateAlerts.sorted(by: {$0.startDate.timeIntervalSince1970 > $1.startDate.timeIntervalSince1970}).first
        } else if newAlertCreatedAlerts.count >= 1 {
            alert = newAlertCreatedAlerts.sorted(by: {$0.startDate.timeIntervalSince1970 > $1.startDate.timeIntervalSince1970}).first
        }
        if alertID != nil {
            activeProductionGlobalAlert = alert
            return false
        }
        let dataWasChanged: Bool = productionGlobalAlertsData != alert
        productionGlobalAlertsData = alert
        return dataWasChanged
    }
    
    func getGlobalProductionIgnoringCache(alertID: String? = nil, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            if let _ = error {
                completion?(false, errorCode, ResponseError.serverError)
            } else {
                self?.handleGlobalProductionAlertsSectionReport(alertID: alertID, reportResponse, errorCode, error, false, completion)
            }
        })
    }
    
    // MARK: - Common methods
    
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
    
    private func getDataIndexes(columns: [ColumnName?]?) -> [String : Int] {
        var indexes: [String : Int] = [:]
        guard let columns = columns?.compactMap({$0}) else { return indexes }
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
