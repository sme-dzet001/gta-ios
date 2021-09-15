//
//  GTTeamDataProvider.swift
//  GTA
//
//  Created by Артем Хрещенюк on 08.09.2021.
//

import Foundation

class GTTeamDataProvider {
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    private(set) var GTTeamContactsData: GTTeamResponse?
    
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
    
    func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
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
