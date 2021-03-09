//
//  CollaborationDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 09.03.2021.
//

import Foundation

class CollaborationDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    
    func getTeamContacts(appSuite: String, completion: ((_ contacts: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleTeamContactsSectionReport(appSuite: appSuite, data, code, cachedError, true, { (data, code, error) in
                if error == nil {
                    completion?(data, code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    if let _ = error {
                        completion?(nil, errorCode, ResponseError.serverError)
                    } else {
                        self?.handleTeamContactsSectionReport(appSuite: appSuite, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleTeamContactsSectionReport(appSuite: String, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ contacts: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.getCollaborationTeamsContacts.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getCollaborationTeamContacts(detailsPath: appSuite)) {[weak self] (data, error) in
                    self?.processTeamContacts(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationTeamContacts(for: generationNumber!, appName: appSuite,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationTeamContacts(detailsPath: appSuite))
                self?.processTeamContacts(reportData, data, errorCode, error, completion)
            })
        } else {
            if let _ = error {
                completion?(nil, errorCode, ResponseError.commonError)
                return
            }
            completion?(nil, errorCode, error)
        }
    }
    
    private func processTeamContacts(_ reportData: ReportDataResponse?, _ appContactsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ appContactsData: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var appContactsData: AppContactsData?
        var retErr = error
        if let responseData = appContactsDataResponse {
            do {
                appContactsData = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        let columns = appContactsData?.meta.widgetsDataSource?.params?.columns
        appContactsData?.indexes = getDataIndexes(columns: columns)
        if let contacts = appContactsData?.contactsData, contacts.isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(appContactsData, errorCode, retErr)
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
        guard let columns = columns else { return indexes }
        for (index, column) in columns.enumerated() {
            if let name = column.name {
                indexes[name] = index
            }
        }
        return indexes
    }
    
}
