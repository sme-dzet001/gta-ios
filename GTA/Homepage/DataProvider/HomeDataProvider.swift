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
    private var imageCacheManager: ImageCacheManager = ImageCacheManager()
    private(set) var userLocationManager: UserLocationManager = UserLocationManager()
    
    private(set) var newsData = [GlobalNewsRow]()
    private(set) var alertsData = [SpecialAlertRow]()
    private(set) var allOfficesData = [OfficeRow]()
    private(set) var GTTeamContactsData: GTTeamResponse?
    private(set) var globalAlertsData: GlobalAlertRow?
    private var selectedOfficeId: Int?
    
    var forceUpdateAlertDetails: Bool = false
    
    weak var officeSelectionDelegate: OfficeSelectionDelegate?
    
    var newsDataIsEmpty: Bool {
        return newsData.isEmpty
    }
    
    var alertsDataIsEmpty: Bool {
        return alertsData.isEmpty
    }
    
    var allOfficesDataIsEmpty: Bool {
        return allOfficesData.isEmpty
    }
    
    private var selectedOffice: OfficeRow? {
        guard let officeId = selectedOfficeId else { return nil }
        return allOfficesData.first { $0.officeId == officeId }
    }
    
    var userOffice: OfficeRow? {
        return selectedOffice
    }
    
    func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
//    func getPosterImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
//        getCachedResponse(for: .getImageDataFor(detailsPath: url.absoluteString), completion: {[weak self] (cachedData, error) in
//            if error == nil {
//                completion(cachedData, nil)
//            }
//            self?.apiManager.loadImageData(from: url) { (data, response, error) in
//                self?.cacheData(data, path: .getImageDataFor(detailsPath: url.absoluteString))
//                DispatchQueue.main.async {
//                    if cachedData == nil ? true : cachedData != data {
//                        completion(data, error)
//                    }
//                }
//            }
//            
//        })
//       // apiManager.loadImageData(from: url, completion: completion)
//    }
    
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
    
    func getGlobalNewsData(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processGlobalNewsSectionReport(data, code, cachedError, true, { (code, error, _) in
                if error == nil {
                    completion?(code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.generate(error: error), false)
                    } else {
                        self?.processGlobalNewsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func processGlobalNewsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalNews.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getGlobalNews) { [weak self] (data, error) in
                    //if let _ = data, error == nil {
                    self?.processGlobalNews(newsResponse: data, reportDataResponse: reportData, isFromCache: true, error: error, errorCode: 200, completion: completion)
                    //}
                }
                return
            }
            apiManager.getGlobalNews(generationNumber: generationNumber) { [weak self] (newsResponse, errorCode, error) in
                if let _ = error {
                    completion?(0, ResponseError.generate(error: error), false)
                    return
                }
                self?.cacheData(newsResponse, path: .getGlobalNews)
                self?.processGlobalNews(newsResponse: newsResponse, reportDataResponse: reportData, isFromCache: false, error: error, errorCode: errorCode, completion: completion)
            }
        } else {
            if error != nil || generationNumber == 0 {
                newsData = generationNumber == 0 ? [] : newsData
                completion?(0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error), isFromCache)
                return
            }
            let retError = ResponseError.serverError
            completion?(0, retError, isFromCache)
        }
    }
    
    private func processGlobalNews(newsResponse: Data?, reportDataResponse: ReportDataResponse?, isFromCache: Bool, error: Error?, errorCode: Int, completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var newsDataResponse: GlobalNewsResponse?
        var retErr = error
        if let responseData = newsResponse {
            do {
                newsDataResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let newsResponse = newsDataResponse {
            self.fillNewsData(with: newsResponse)
            if (newsResponse.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(errorCode, retErr, isFromCache)
    }
    
    private func fillNewsData(with newsResponse: GlobalNewsResponse) {
        let indexes = getDataIndexes(columns: newsResponse.meta?.widgetsDataSource?.params?.columns)
        var response: GlobalNewsResponse = newsResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index]?.indexes = indexes
            }
        }
        newsData = response.data?.rows?.compactMap({$0}) ?? []
    }
    
    private func processSpecialAlerts(_ reportData: ReportDataResponse?, _ alertsResponse: Data?, _ isFromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var specialAlertsDataResponse: SpecialAlertsResponse?
        var retErr = error
        if let responseData = alertsResponse {
            do {
                specialAlertsDataResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let alertsResponse = specialAlertsDataResponse {
            fillAlertsData(with: alertsResponse)
            if (alertsResponse.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(errorCode, retErr, isFromCache)
    }
    
    private func processSpecialAlertsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalNews.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.specialAlerts.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getSpecialAlerts) {[weak self] (data, error) in
                    //if let _ = data, error == nil {
                    self?.processSpecialAlerts(reportData, data, true, 200, error, completion)
                    //}
                }
                return
            }
            apiManager.getSpecialAlerts(generationNumber: generationNumber, completion: { [weak self] (alertsResponse, errorCode, error) in
                if let _ = error {
                    completion?(0, ResponseError.generate(error: error), false)
                    return
                }
                self?.cacheData(alertsResponse, path: .getSpecialAlerts)
                self?.processSpecialAlerts(reportData, alertsResponse, false, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(0, generationNumber == 0 ? ResponseError.noDataAvailable: ResponseError.generate(error: error), isFromCache)
                return
            }
            let retError = ResponseError.serverError
            completion?(0, retError, isFromCache)
        }
    }
    
    func getSpecialAlertsData(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processSpecialAlertsSectionReport(data, code, cachedError, true, { (code, error, _) in
                if error == nil {
                    completion?(code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.generate(error: error), false)
                    } else {
                        self?.processSpecialAlertsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func fillAlertsData(with alertsResponse: SpecialAlertsResponse) {
        let indexes = getDataIndexes(columns: alertsResponse.meta?.widgetsDataSource?.params?.columns)
        var response: SpecialAlertsResponse = alertsResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index]?.indexes = indexes
            }
        }
        alertsData = response.data?.rows?.compactMap({$0}) ?? []
    }
    
    // MARK: - Office related methods
    
    func getAllOfficesData(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processAllOfficesSectionReport(data, code, cachedError, true, { (code, error) in
                if error == nil {
                    completion?(code, cachedError)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.generate(error: error))
                    } else {
                        self?.processAllOfficesSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func processAllOfficesSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.officeStatus.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.allOffices.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getAllOffices) {[weak self] (data, error) in
                    self?.processAllOffices(reportData, data, 200, error, completion)
                }
                return
            }
            apiManager.getAllOffices(generationNumber: generationNumber) { [weak self] (officesResponse, errorCode, error) in
                if let _ = error {
                    completion?(0, ResponseError.generate(error: error))
                    return
                }
                self?.cacheData(officesResponse, path: .getAllOffices)
                self?.processAllOffices(reportData, officesResponse, errorCode, error, completion)
            }
        } else {
            if error != nil || generationNumber == 0 {
                completion?(0, generationNumber == 0 ? ResponseError.noDataAvailable: ResponseError.generate(error: error))
                return
            }
            completion?(0, error)
        }
    }
    
    private func processAllOffices(_ reportData: ReportDataResponse?, _ officesResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var allOfficesResponse: AllOfficesResponse?
        var retErr = error
        if let responseData = officesResponse {
            do {
                allOfficesResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let officesResponse = allOfficesResponse {
            fillAllOfficesData(with: officesResponse)
        }
        completion?(errorCode, retErr)
    }
    
    private func fillAllOfficesData(with officesResponse: AllOfficesResponse) {
        let indexes = getDataIndexes(columns: officesResponse.meta?.widgetsDataSource?.params?.columns)
        var response: AllOfficesResponse = officesResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index]?.indexes = indexes
            }
        }
        response.data?.rows?.removeAll { ($0?.officeName?.isEmpty ?? true) || ($0?.officeName?.isEmpty ?? true) }
        allOfficesData = response.data?.rows?.compactMap({$0}) ?? []
    }
    
    func getAllOfficeRegions() -> [String] {
        let regions = allOfficesData.compactMap { $0.officeRegion }
        return regions.removeDuplicates().sorted()
    }
    
    func getOffices(for region: String) -> [OfficeRow] {
        let selectedRegionOffices = allOfficesData.filter { $0.officeRegion == region }
        let sortedOffices = selectedRegionOffices.sorted { ($0.officeName ?? "") < ($1.officeName ?? "") }
        return sortedOffices
    }
    
    func getOfficeNames(for region: String) -> [String] {
        return getOffices(for: region).compactMap { $0.officeName }
    }
    
    /// - Returns: false - if user denied to get his location, otherwise returns true (user accepted to get his location, or his choice is not determined yet)
    func getClosestOffice() -> Bool {
        let officesCoordinates = allOfficesData.filter { $0.officeLatitude != nil && $0.officeLongitude != nil }.map { (lat: $0.officeLatitude!, long: $0.officeLongitude!) }
        userLocationManager.officesCoordArray = officesCoordinates
        return userLocationManager.getCurrentUserLocation()
    }
    
    func getClosestOfficeId(by coord: (lat: Float, long: Float)) -> Int? {
        let officeId = allOfficesData.first { $0.officeLatitude == coord.lat && $0.officeLongitude == coord.long }?.officeId
        return officeId
    }
    
    func getCurrentOffice(completion: ((_ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getCurrentPreferences) {[weak self] (data, cacheError) in
            self?.processGetCurrentOffice(data, cacheError == nil ? 200 : 0, cacheError, true, { (code, error, _) in
                if error == nil {
                    completion?(code, error, true)
                }
                self?.apiManager.getCurrentPreferences { [weak self] (response, errorCode, error) in
                    if let _ = error {
                        completion?(code, ResponseError.generate(error: error), false)
                        return
                    }
                    self?.cacheData(response, path: .getCurrentPreferences)
                    self?.processGetCurrentOffice(response, errorCode, error, false, completion)
                }
            })
        }
    }
    
    private func processGetCurrentOffice(_ currentOfficeResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        var userPreferencesResponse: UserPreferencesResponse?
        var retErr = error
        if let responseData = currentOfficeResponse {
            do {
                userPreferencesResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let userPreferencesResponse = userPreferencesResponse {
            if !fromCache || selectedOfficeId == nil {
                selectedOfficeId = Int(userPreferencesResponse.data.preferences?.officeId ?? "")
                Preferences.officeId = Int(userPreferencesResponse.data.preferences?.officeId ?? "")
                Preferences.allowEmergencyOutageNotifications = userPreferencesResponse.data.preferences?.allowEmergencyOutageNotifications ?? true
                Preferences.allowProductionAlertsNotifications = userPreferencesResponse.data.preferences?.allowProductionAlertsNotifications ?? true
            }
        }
        completion?(errorCode, retErr, fromCache)
    }
    
    func setCurrentOffice(officeId: Int, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let preferences = "{\"office_id\":\"\(officeId)\", \"allow_notifications_emergency_outage\": \(Preferences.allowEmergencyOutageNotifications), \"allow_notifications_production_alerts\": \(Preferences.allowProductionAlertsNotifications)}"
        apiManager.setCurrentPreferences(preferences: preferences) { [weak self] (response, errorCode, error) in
            if let _ = response, errorCode == 200, error == nil {
                self?.officeSelectionDelegate?.officeWasSelected()
                self?.selectedOfficeId = officeId
                Preferences.officeId = officeId
            }
            completion?(errorCode, error)
        }
    }
    
    // MARK: - Global Alerts related methods
    
    func getGlobalAlerts(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.processGlobalAlertsSectionReport(data, code, cachedError, true, { (dataWasChanged, code, error) in
                if error == nil {
                    completion?(dataWasChanged, code, cachedError)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, errorCode, ResponseError.generate(error: error))
                    } else {
                        self?.processGlobalAlertsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    func getGlobalAlertsIgnoringCache(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
            self?.cacheData(reportResponse, path: .getSectionReport)
            if let _ = error {
                completion?(false, errorCode, ResponseError.serverError)
            } else {
                self?.processGlobalAlertsSectionReport(reportResponse, errorCode, error, false, completion)
            }
        })
    }
    
    private func processGlobalAlertsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.globalAlerts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.globalAlerts.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if isFromCache {
                getCachedResponse(for: .getGlobalOutage) {[weak self] (data, error) in
                    self?.processGlobalAlerts(reportData, data, 200, error, completion)
                }
                return
            }
            apiManager.getGlobalAlerts(generationNumber: generationNumber) { [weak self] (response, errorCode, error) in
                if let _ = error {
                    completion?(true, 0, ResponseError.generate(error: error))
                    return
                }
                self?.cacheData(response, path: .getGlobalOutage)
                self?.processGlobalAlerts(reportData, response, errorCode, error, completion)
            }
        } else {
            if error != nil || generationNumber == 0 {
                completion?(false, 0, generationNumber == 0 ? ResponseError.noDataAvailable: ResponseError.generate(error: error))
                return
            }
            completion?(false, 0, error)
        }
    }
    
    private func processGlobalAlerts(_ reportData: ReportDataResponse?, _ response: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
        completion?(dataWasChanged, errorCode, retErr)
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
        let indexes = getDataIndexes(columns: prodAlertsResponse?.meta?.widgetsDataSource?.params?.columns)
        let count = getProductionAlertsCount(sdsd: data, indexes: indexes)
        completion?(errorCode, retErr, count)
    }
    
    private func getProductionAlertsCount(sdsd: [String : ProductionAlertsData], indexes: [String : Int]) -> Int {
        var data = sdsd
        var count = 0
        for key in data.keys {
            for (index, _) in (data[key]?.data?.rows ?? []).enumerated() {
                data[key]?.data?.rows?[index]?.indexes = indexes
            }
            count += data[key]?.data?.rows?.filter({$0?.isRead == false && $0?.isExpired == false}).count ?? 0
        }
        return count
    }
    
    
    // MARK: - Common methods
    
//    private func getSectionReport(completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
//        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
//            if let _ = data, cachedError == nil {
//                completion?(data, 200, cachedError, true)
//            }
//            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
//                self?.cacheData(reportResponse, path: .getSectionReport)
//                var newError = error
//                if let _ = error {
//                    newError = ResponseError.serverError
//                }
//                completion?(reportResponse, errorCode, newError, false)
//            })
//        }
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
