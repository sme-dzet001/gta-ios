//
//  GeneralDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.05.2021.
//

import Foundation

class GeneralDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    
    private var selectedOfficeId: Int?
    private var needToGetDataFromServer: Bool = false
 
    func getCurrentPreferences(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        if !needToGetDataFromServer {
            getCachedResponse(for: .getCurrentPreferences) {[weak self] (data, cacheError) in
                self?.processGetCurrentPreferences(data, cacheError == nil ? 200 : 0, cacheError, { (code, error) in
                    if error == nil {
                        completion?(code, error)
                    }
                    self?.getCurrentPreferencesFromServer(completion: completion)
                })
            }
        } else {
            self.getCurrentPreferencesFromServer(completion: completion)
        }
    }
    
    private func getCurrentPreferencesFromServer(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        self.apiManager.getCurrentPreferences { [weak self] (response, errorCode, error) in
            self?.cacheData(response, path: .getCurrentPreferences)
            if let _ = error {
                completion?(0, ResponseError.generate(error: error))
            } else {
                self?.processGetCurrentPreferences(response, errorCode, error, completion)
            }
        }
    }
    
    private func processGetCurrentPreferences(_ response: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var userPreferencesResponse: UserPreferencesResponse?
        var retErr = error
        if let responseData = response {
            do {
                userPreferencesResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let userPreferencesResponse = userPreferencesResponse {
            selectedOfficeId = Int(userPreferencesResponse.data.preferences?.officeId ?? "")
            Preferences.allowProductionAlertsNotifications = userPreferencesResponse.data.preferences?.allowProductionAlertsNotifications ?? true
            Preferences.allowEmergencyOutageNotifications = userPreferencesResponse.data.preferences?.allowEmergencyOutageNotifications ?? true
        }
        completion?(errorCode, retErr)
    }
    
    func setCurrentPreferences(notificationsState: Bool, notificationsType: NotificationsType, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        needToGetDataFromServer = true
        let officeId = Preferences.officeId ?? selectedOfficeId ?? 0
        let prodAlertsState = Preferences.allowProductionAlertsNotifications
        let emergencyOutageState = Preferences.allowEmergencyOutageNotifications
        var preferences = ""
        switch notificationsType {
        case .emergencyOutageNotifications:
            preferences = "{\"office_id\":\"\(officeId)\", \"allow_notifications_emergency_outage\": \(notificationsState), \"allow_notifications_production_alerts\": \(prodAlertsState)}"
            Preferences.allowEmergencyOutageNotifications = notificationsState
        default:
            preferences = "{\"office_id\":\"\(officeId)\", \"allow_notifications_emergency_outage\": \(emergencyOutageState), \"allow_notifications_production_alerts\": \(notificationsState)}"
            Preferences.allowProductionAlertsNotifications = notificationsState
        }
        apiManager.setCurrentPreferences(preferences: preferences) {(response, errorCode, error) in
            if let _ = response, errorCode == 200, error == nil {
            } else {
                if notificationsType == .emergencyOutageNotifications {
                    Preferences.allowEmergencyOutageNotifications = !notificationsState
                } else {
                    Preferences.allowProductionAlertsNotifications = !notificationsState
                }
                completion?(errorCode, ResponseError.generate(error: error))
                return
            }
            completion?(errorCode, error)
        }
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

enum NotificationsType {
    case emergencyOutageNotifications
    case productionAlertsNotifications
}
