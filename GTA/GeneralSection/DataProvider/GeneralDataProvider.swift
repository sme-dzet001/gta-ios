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
    private(set) var allowEmergencyOutageNotifications: Bool = true
    
    func getCurrentPreferences(completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getCurrentPreferences) {[weak self] (data, cacheError) in
            self?.processGetCurrentPreferences(data, cacheError == nil ? 200 : 0, cacheError, { (code, error) in
                if error == nil {
                    completion?(code, error)
                }
                self?.apiManager.getCurrentPreferences { [weak self] (response, errorCode, error) in
                    self?.cacheData(response, path: .getCurrentPreferences)
                    self?.processGetCurrentPreferences(response, errorCode, error, completion)
                }
            })
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
            allowEmergencyOutageNotifications = userPreferencesResponse.data.preferences?.allowEmergencyOutageNotifications ?? true
            Preferences.allowEmergencyOutageNotifications = userPreferencesResponse.data.preferences?.allowEmergencyOutageNotifications ?? true
        }
        completion?(errorCode, retErr)
    }
    
    func setCurrentPreferences(nottificationsState: Bool, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let officeId = Preferences.officeId ?? selectedOfficeId ?? 0
        let preferences = "{\"office_id\":\"\(officeId)\", \"allow_notifications_emergency_outage\": \(nottificationsState)}"
        apiManager.setCurrentPreferences(preferences: preferences) { [weak self] (response, errorCode, error) in
            if let _ = response, errorCode == 200, error == nil {
                //self?.officeSelectionDelegate?.officeWasSelected()
                self?.allowEmergencyOutageNotifications = nottificationsState
                Preferences.allowEmergencyOutageNotifications = nottificationsState
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
