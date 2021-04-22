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
    private(set) var collaborationNewsData = [CollaborationNewsRow]()
    private(set) var collaborationDetails: CollaborationDetailsResponse?
    private var appSuiteImage: Data?
    weak var appSuiteIconDelegate: AppSuiteIconDelegate?
    private(set) var collaborationAppDetailsRows: [CollaborationAppDetailsRow]?
    private(set) var appContactsData: AppContactsData?
    
    // MARK: - Collaboration details handling
    
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
        if let _ = generationNumber, generationNumber! != 0 {
            if fromCache {
                getCachedResponse(for: .getCollaborationDetails(detailsPath: appSuite)) {[weak self] (data, error) in
                    self?.processCollaborationDetails(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationDetails(for: generationNumber!, appName: appSuite,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationDetails(detailsPath: appSuite))
                self?.processCollaborationDetails(reportData, data, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable)
                return
            }
            completion?(0, ResponseError.commonError)
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
        //getAppImage(from: detailsData?.icon)
        completion?(errorCode, retErr)
    }
    
//    private func getAppImage(from urlString: String?, completion: ((_ imageData: Data?, _ error: Error?) -> Void)? = nil) {
//        getAppImageData(from: urlString) { (imageData, error) in
//            if self.appSuiteImage == nil || imageData != self.appSuiteImage {
//                self.appSuiteImage = imageData
//                self.appSuiteIconDelegate?.appSuiteIconChanged(with: imageData, status: error == nil ? .loaded : .failed)
//            }
//        }
//    }
    
    // MARK: - What's new handling
    
    func getWhatsNewData(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (reportResponse, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleWhatsNewSectionReport(reportResponse, code, cachedError, true, { (dataWasChanged, code, error) in
                if error == nil {
                    completion?(dataWasChanged, code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, errorCode, ResponseError.serverError)
                    } else {
                        self?.handleWhatsNewSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleWhatsNewSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationNews.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getCollaborationNews) {[weak self] (data, error) in
                    self?.processWhatsNew(reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationNews(for: generationNumber!, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationNews)
                self?.processWhatsNew(reportData, data, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                self.collaborationNewsData = generationNumber == 0 ? [] : collaborationNewsData
                completion?(false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable)
                return
            }
            completion?(false, 0, error)
        }
    }
    
    private func processWhatsNew(_ reportData: ReportDataResponse?, _ newsData: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var newsResponse: CollaborationNewsResponse?
        var retErr = error
        if let responseData = newsData {
            do {
                newsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        var isDataChanged: Bool = false
        if let response = newsResponse {
            isDataChanged = fillNewsData(with: response)
            if (response.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(isDataChanged, errorCode, retErr)
    }
    
    private func fillNewsData(with dataResponse: CollaborationNewsResponse) -> Bool {
        let indexes = getDataIndexes(columns: dataResponse.meta?.widgetsDataSource?.params?.columns)
        var response: CollaborationNewsResponse = dataResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        if collaborationNewsData != response.data?.rows ?? [] {
            collaborationNewsData = response.data?.rows ?? []
            for (index, row) in (response.data?.rows ?? []).enumerated() {
                collaborationNewsData[index].decodeBody = formAnswerBody(from: row.body)
            }
            return true
        }
        return false
    }
    
    // MARK: - Tips & Tricks handling
    
    func getTipsAndTricks(appSuite: String, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (reportResponse, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleTipsAndTricksSectionReport(appSuite: appSuite, reportResponse, code, cachedError, true, { (dataWasChanged, code, error, _) in
                if error == nil {
                    completion?(dataWasChanged, code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, errorCode, ResponseError.serverError, false)
                    } else {
                        self?.handleTipsAndTricksSectionReport(appSuite: appSuite, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleTipsAndTricksSectionReport(appSuite: String, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationTipsAndTricks.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getCollaborationTipsAndTricks(detailsPath: appSuite)) {[weak self] (data, error) in
                    self?.processTipsAndTricks(reportData, data, true, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationTipsAndTricks(for: generationNumber!, appName: appSuite,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationTipsAndTricks(detailsPath: appSuite))
                self?.processTipsAndTricks(reportData, data, false, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                self.tipsAndTricksData = generationNumber == 0 ? [] : tipsAndTricksData
                completion?(false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(false, 0, error, fromCache)
        }
    }
    
    private func processTipsAndTricks(_ reportData: ReportDataResponse?, _ tipsAndTricksData: Data?, _ fromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
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
        var isDataChanged: Bool = false
        if let response = tipsAndTricksResponse {
            isDataChanged = fillTipsAndTricksData(with: response)
            if (response.data?.first?.value?.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(isDataChanged, errorCode, retErr, fromCache)
    }
    
    
    // MARK: - Team contacts handling
    
    func getTeamContacts(appSuite: String, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleTeamContactsSectionReport(appSuite: appSuite, data, code, cachedError, true, { (dataWasChanged, code, error) in
                if error == nil {
                    completion?(dataWasChanged, code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, errorCode, ResponseError.serverError)
                    } else {
                        self?.handleTeamContactsSectionReport(appSuite: appSuite, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleTeamContactsSectionReport(appSuite: String, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaboration.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationTeamsContacts.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
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
            if error != nil || generationNumber == 0 {
                completion?(generationNumber == 0 ? true : false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable)
                return
            }
            completion?(false, 0, error)
        }
    }
    
    private func processTeamContacts(_ reportData: ReportDataResponse?, _ appContactsDataResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
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
        var dataWasChanged: Bool = false
        if appContactsData == nil && self.appContactsData != nil {
        } else if appContactsData != self.appContactsData {
            self.appContactsData = appContactsData
            dataWasChanged = true
        }
        
        completion?(dataWasChanged, errorCode, retErr)
    }
    
    // MARK: - App details handling
    
    func getAppDetails(appSuite: String, completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (reportResponse, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleAppDetailsSectionReport(appSuite: appSuite, reportResponse, code, cachedError, true, { (dataWasChanged, code, error) in
                if error == nil {
                    completion?(dataWasChanged, code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(dataWasChanged, errorCode, ResponseError.serverError)
                    } else {
                        self?.handleAppDetailsSectionReport(appSuite: appSuite, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleAppDetailsSectionReport(appSuite: String, _ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaborationAppDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationAppDetailsV1.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getCollaborationAppDetails(detailsPath: appSuite)) {[weak self] (data, error) in
                    self?.processAppDetails(appSuite, reportData, data, errorCode, error, completion)
                }
                return
            }
            apiManager.getCollaborationAppDetails(for: generationNumber!, appName: appSuite,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationAppDetails(detailsPath: appSuite))
                self?.processAppDetails(appSuite, reportData, data, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(generationNumber == 0 ? true : false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable)
                return
            }
            completion?(false, 0, error)
        }
    }
    
    private func processAppDetails(_ appName: String, _ reportData: ReportDataResponse?, _ detailsResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var detailsData: CollaborationAppDetailsResponse?
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
        if let rows = detailsData?.data?[appName]??.data?.rows {
            retErr = rows.isEmpty ? ResponseError.noDataAvailable : retErr
            let indexes = getDataIndexes(columns: columns)
            for (index, _) in rows.enumerated() {
                detailsData?.data?[appName]??.data?.rows?[index].indexes = indexes
                let url = formImageURL(from: detailsData?.data?[appName]??.data?.rows?[index].imageUrl)
                detailsData?.data?[appName]??.data?.rows?[index].fullImageUrl = url
            }
        }
        var dataWasChanged: Bool = false
        if detailsData?.data?.first?.value?.data?.rows != self.collaborationAppDetailsRows {
            if detailsData?.data?.first?.value?.data?.rows == nil && self.collaborationAppDetailsRows != nil {
            } else {
                self.collaborationAppDetailsRows = detailsData?.data?.first?.value?.data?.rows
                dataWasChanged = true
            }
            
        }
//        DispatchQueue.main.async {
//            if let rows = detailsData?.data?[appName]??.data?.rows {
//                //self.getRowsImageData(for: rows)
//            }
//        }
        completion?(dataWasChanged, errorCode, retErr)
    }
    
//    func getRowsImageData(for appInfo: [ImageDataProtocol]) {
//        for (index, info) in appInfo.enumerated() {
//            if let url = info.imageUrl {
//                getAppImageData(from: url) { (imageData, error) in
//                    if info.imageData == nil || (imageData != nil && imageData != info.imageData) {
//                        self.collaborationAppDetailsRows?[index].imageData = imageData
//                        self.collaborationAppDetailsRows?[index].imageStatus = error == nil ? .loaded : .failed
//                        //self.imageLoadingDelegate?.setImage(for: info.imageUrl ?? "")
//                    }
//                }
//            } else {
//                self.collaborationAppDetailsRows?[index].imageStatus = .failed
//                //self.imageLoadingDelegate?.setImage(for: info.imageUrl ?? "")
//            }
//        }
//    }
    
    // MARK:- Additional methods
    
    func addArticle(_ article: String) {
        if var arr = UserDefaults.standard.array(forKey: "NumberOfNews") as? [Data] {
            guard let data = article.data(using: .utf8), !arr.contains(data) else { return }
            arr.append(data)
            UserDefaults.standard.setValue(arr, forKey: "NumberOfNews")
        } else {
            UserDefaults.standard.setValue([article.data(using: .utf8) as Any], forKey: "NumberOfNews")
        }
    }
    
    func getUnreadArticlesNumber() -> Int? {
        var number: Int = 0
        guard let storedArticle = UserDefaults.standard.array(forKey: "NumberOfNews") as? [Data] else { return self.collaborationNewsData.count }
        for data in self.collaborationNewsData {
            if let bodyData = data.body?.data(using: .utf8), !storedArticle.contains(bodyData) {
                number += 1
            }
        }
        return number != 0 ? number : nil
    }
    
//    func getAppImageData(from urlString: String?, completion: ((_ imageData: Data?, _ error: Error?) -> Void)? = nil) {
//        if let urlString = urlString, let url = URL(string: formImageURL(from: urlString.components(separatedBy: .whitespaces).joined())) {
//            getCachedResponse(for: .getImageDataFor(detailsPath: url.absoluteString), completion: {[weak self] (cachedData, cachedError) in
//                if cachedError == nil {
//                    completion?(cachedData, cachedError)
//                }
//                self?.apiManager.loadImageData(from: url) { (data, response, error) in
//                    self?.cacheData(data, path: .getImageDataFor(detailsPath: url.absoluteString))
//                    DispatchQueue.main.async {
//                        if cachedData == nil ? true : cachedData != data {
//                            if cachedError == nil && error != nil { return }
//                            completion?(data, error)
//                        }
//                    }
//                }
//                
//            })
//        } else {
//            completion?(nil, ResponseError.commonError)
//        }
//    }
    
    func formImageURL(from imagePath: String?) -> String {
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
    
    private func fillTipsAndTricksData(with dataResponse: CollaborationTipsAndTricksResponse) -> Bool {
        let indexes = getDataIndexes(columns: dataResponse.meta?.widgetsDataSource?.params?.columns)
        var response: CollaborationTipsAndTricksResponse = dataResponse
        let key = response.data?.keys.first ?? ""
        if let rows = response.data?.first?.value?.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?[key]??.data?.rows?[index].indexes = indexes
            }
        }
        if tipsAndTricksData != response.data?[key]??.data?.rows ?? [] {
            tipsAndTricksData = response.data?[key]??.data?.rows ?? []
            return true
        }
        return false
    }
    
    func formAnswerBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
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
    func appSuiteIconChanged(with data: Data?, status: LoadingStatus)
}
