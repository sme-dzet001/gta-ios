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
    private var imageCacheManager: ImageCacheManager = ImageCacheManager()
    private(set) var tipsAndTricksData = [TipsAndTricksRow]()
    private(set) var collaborationDetails: CollaborationDetailsResponse?
    private var appSuiteImage: Data?
    weak var appSuiteIconDelegate: AppSuiteIconDelegate?
    
    
    // MARK: - News handling
    
    func getCollaborationDetails(appSuite: String, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (reportResponse, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleCollaborationDetailsSectionReport(appSuite: appSuite, reportResponse, code, cachedError, true, { (code, error) in
                if error == nil {
                    completion?(code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?( errorCode, ResponseError.serverError)
                    } else {
                        self?.handleCollaborationDetailsSectionReport(appSuite: appSuite, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleCollaborationDetailsSectionReport(appSuite: String, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaboration.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getCollaborationDetails(detailsPath: appSuite)) {[weak self] (data, error) in
                    self?.processCollaborationDetails(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationNews(for: generationNumber!, appName: appSuite,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationDetails(detailsPath: appSuite))
                self?.processCollaborationDetails(reportData, data, errorCode, error, completion)
            })
        } else {
            if let _ = error {
                completion?(errorCode, ResponseError.commonError)
                return
            }
            completion?(errorCode, error)
        }
    }
    
    private func processCollaborationDetails(_ reportData: ReportDataResponse?, _ detailsResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var detailsData: CollaborationDetailsResponse?
        var retErr = error
        if let responseData = detailsResponse {
            do {
                detailsData = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        let columns = detailsData?.meta?.widgetsDataSource?.params?.columns
        detailsData?.indexes = getDataIndexes(columns: columns)
        if let _ = detailsData, detailsData!.isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        if detailsData != self.collaborationDetails {
            self.collaborationDetails = detailsData
        }
        getAppImageData(from: detailsData?.icon)
        completion?(errorCode, retErr)
    }
    
    
    
    // MARK: - Tips & Tricks handling
    
    func getTipsAndTricks(appSuite: String, completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (reportResponse, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleTipsAndTricksSectionReport(appSuite: appSuite, reportResponse, code, cachedError, true, { (code, error) in
                if error == nil {
                    completion?(code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?( errorCode, ResponseError.serverError)
                    } else {
                        self?.handleTipsAndTricksSectionReport(appSuite: appSuite, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleTipsAndTricksSectionReport(appSuite: String, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationTipsAndTricks.rawValue }?.generationNumber
        if let _ = generationNumber {
            if fromCache {
                getCachedResponse(for: .getCollaborationTipsAndTricks(detailsPath: appSuite)) {[weak self] (data, error) in
                    self?.processTipsAndTricks(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationTipsAndTricks(for: generationNumber!, appName: appSuite,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationTipsAndTricks(detailsPath: appSuite))
                self?.processTipsAndTricks(reportData, data, errorCode, error, completion)
            })
        } else {
            if let _ = error {
                completion?(errorCode, ResponseError.commonError)
                return
            }
            completion?(errorCode, error)
        }
    }
    
    private func processTipsAndTricks(_ reportData: ReportDataResponse?, _ tipsAndTricksData: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var tipsAndTricksResponse: CollaborationTipsAndTricksResponse?
        var retErr = error
        if let responseData = tipsAndTricksData {
            do {
                tipsAndTricksResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        if let response = tipsAndTricksResponse {
            fillTipsAndTricksData(with: response)
            if (response.data?.first?.value?.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(errorCode, retErr)
    }
    
    
    // MARK: - Team contacts handling
    func getTeamContacts(appSuite: String, completion: ((_ contacts: AppContactsData?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleTeamContactsSectionReport(appSuite: appSuite, data, code, cachedError, true, { (data, code, error) in
                if error == nil {
                    completion?(data, code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
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
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationTeamsContacts.rawValue }?.generationNumber
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
        appContactsData?.isCollaboration = true
        if let contacts = appContactsData?.contactsData, contacts.isEmpty {
            retErr = ResponseError.noDataAvailable
        }
        completion?(appContactsData, errorCode, retErr)
    }
    
    // MARK:- Additional methods
    
    private func getAppImageData(from urlString: String?) {
        guard let url = URL(string: formImageURL(from: urlString ?? "")) else { return }
        if let cachedResponse = imageCacheManager.getCacheResponse(for: url), cachedResponse != appSuiteImage {
            self.appSuiteIconDelegate?.appSuiteIconChanged(with: cachedResponse)
        } else {
            apiManager.loadImageData(from: url) { (data, response, error) in
                self.imageCacheManager.storeCacheResponse(response, data: data)
                if data != self.appSuiteImage {
                    self.appSuiteIconDelegate?.appSuiteIconChanged(with: data)
                }
            }
        }
    }
    
    private func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath else { return "" }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
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
    
    private func fillTipsAndTricksData(with dataResponse: CollaborationTipsAndTricksResponse) {
        let indexes = getDataIndexes(columns: dataResponse.meta?.widgetsDataSource?.params?.columns)
        var response: CollaborationTipsAndTricksResponse = dataResponse
        let key = response.data?.keys.first ?? ""
        if let rows = response.data?.first?.value?.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?[key]??.data?.rows?[index].indexes = indexes
            }
        }
        tipsAndTricksData = response.data?[key]??.data?.rows ?? []
    }
    
    func formTipsAndTricksAnswerBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
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
    
}

protocol AppSuiteIconDelegate: class {
    func appSuiteIconChanged(with data: Data?)
}
