//
//  MenuViewControllerDataProvider.swift
//  GTA
//
//  Created by Артем Хрещенюк on 08.09.2021.
//

import Foundation

class MenuViewControllerDataProvider {
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    
    private(set) var userLocationManager: UserLocationManager = UserLocationManager()
    private(set) var allOfficesData = [OfficeRow]()
    private var selectedOfficeId: Int?
    weak var officeSelectionDelegate: OfficeSelectionDelegate?
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
