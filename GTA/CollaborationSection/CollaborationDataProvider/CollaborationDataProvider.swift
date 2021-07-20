//
//  CollaborationDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 09.03.2021.
//

import Foundation
import UIKit

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
    private var receivedMetricsData: CollaborationMetricsResponse?
    private(set) var horizontalChartData: [String : [TeamsChatUserDataEntry]]?
    private(set) var verticalChartData: ChartStructure?
    private(set) var activeUsersLineChartData: ChartStructure?
    private(set) var teamsByFunctionsLineChartData: [String : [[TeamsByFunctionsDataEntry]]]?
    
    var isChartDataEmpty: Bool {
        return teamsByFunctionsLineChartData == nil && activeUsersLineChartData == nil &&  verticalChartData == nil &&  horizontalChartData == nil
    }
    
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
                        completion?( errorCode, ResponseError.generate(error: error))
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
                if let _ = error {
                    completion?(0, ResponseError.generate(error: error))
                } else {
                    self?.processCollaborationDetails(reportData, data, errorCode, error, completion)
                }
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error))
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
        completion?(errorCode, retErr)
    }
    
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
                        completion?(false, errorCode, ResponseError.generate(error: error))
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
                if let _ = error {
                    completion?(false, 0, ResponseError.generate(error: error))
                } else {
                    self?.processWhatsNew(reportData, data, errorCode, error, completion)
                }
            })
        } else {
            if error != nil || generationNumber == 0 {
                self.collaborationNewsData = generationNumber == 0 ? [] : collaborationNewsData
                completion?(false, 0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error))
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
                        completion?(false, errorCode, ResponseError.generate(error: error), false)
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
                if let _ = error {
                    completion?(false, 0, ResponseError.generate(error: error), false)
                } else {
                    self?.processTipsAndTricks(reportData, data, false, errorCode, error, completion)
                }
            })
        } else {
            if error != nil || generationNumber == 0 {
                self.tipsAndTricksData = generationNumber == 0 ? [] : tipsAndTricksData
                completion?(false, 0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error), fromCache)
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
                        completion?(false, errorCode, ResponseError.generate(error: error))
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
                if let _ = error {
                    completion?(false, 0, ResponseError.generate(error: error))
                } else {
                    self?.processTeamContacts(reportData, data, errorCode, error, completion)
                }
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(generationNumber == 0 ? true : false, 0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error))
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
                        completion?(dataWasChanged, errorCode, ResponseError.generate(error: error))
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
                if let _ = error {
                    completion?(false, 0, ResponseError.generate(error: error))
                } else {
                    self?.processAppDetails(appSuite, reportData, data, errorCode, error, completion)
                }
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(generationNumber == 0 ? true : false, 0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error))
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
        completion?(dataWasChanged, errorCode, retErr)
    }
    
    // MARK: - Usage metrics related methods
    
    func getUsageMetrics(completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (reportResponse, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleUsageMetricsSectionReport(reportResponse, code, cachedError, true, { (fromCache, dataWasChanged, code, error) in
                if error == nil {
                    completion?(fromCache, dataWasChanged, code, error)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(false, dataWasChanged, errorCode, ResponseError.generate(error: error))
                    } else {
                        self?.handleUsageMetricsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleUsageMetricsSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.collaborationAppDetails.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.collaborationAppDetailsV1.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getCollaborationMetrics) {[weak self] (data, error) in
                    self?.processUsageMetrics(reportData, data, errorCode, error, true, completion)
                }
                return
            }
            apiManager.getCollaborationMetrics(for: generationNumber!,  completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getCollaborationMetrics)
                if let _ = error {
                    completion?(fromCache, false, 0, ResponseError.generate(error: error))
                } else {
                    self?.processUsageMetrics(reportData, data, errorCode, error, fromCache, completion)
                }
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(fromCache, generationNumber == 0 ? true : false, 0, generationNumber == 0 ? ResponseError.noDataAvailable : ResponseError.generate(error: error))
                return
            }
            completion?(fromCache, false, 0, error)
        }
    }
    
    private func processUsageMetrics(_ reportData: ReportDataResponse?, _ detailsResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool,  _ completion: ((_ isFromCache: Bool, _ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        var metricsData: CollaborationMetricsResponse?
        var retErr = error
        if let responseData = detailsResponse {
            do {
                metricsData = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        } else {
            retErr = ResponseError.commonError
        }
        let columns = metricsData?.meta?.widgetsDataSource?.params?.columns
        let indexes = getDataIndexes(columns: columns)
        var rows = metricsData?.collaborationMetricsData?.data?.rows ?? []
        
        for (index, _) in rows.enumerated() {
            rows[index]?.indexes = indexes
        }
        let dataWasChanged: Bool = receivedMetricsData != metricsData
        if dataWasChanged {
            receivedMetricsData = metricsData
            fillChartsData(for: rows)
        }
        completion?(isFromCache, dataWasChanged, errorCode, retErr)
    }
    
    private func fillChartsData(for rows: [CollaborationMetricsRow?]) {
        let horizontalBars = rows.filter({$0?.chartType == .horizontalBar})
        fillHorizontalChartData(for: horizontalBars)
        let verticalBars = rows.filter({$0?.chartType == .verticalBar})
        fillVerticalChartData(for: verticalBars)
        let activeUsers = rows.filter({$0?.chartType == .line && $0?.chartSubtitle == nil})
        fillActiveUsersLineChartData(for: activeUsers)
        let teamsByFunctions = rows.filter({$0?.chartType == .line && $0?.chartSubtitle != nil})
        fillTeamsByFunctionsLineChartData(for: teamsByFunctions)
    }
    
    private func fillHorizontalChartData(for rows: [CollaborationMetricsRow?]) {
        let title = rows.compactMap({$0?.chartTitle}).first
        guard let _ = title else { return }
        var data = [TeamsChatUserDataEntry]()
        for row in rows {
            data.append(TeamsChatUserDataEntry(percent: Double(row?.value ?? 0), countryCode: row?.legend ?? ""))
        }
        horizontalChartData = [:]
        horizontalChartData?[title!] = data
    }
    
    private func fillVerticalChartData(for rows: [CollaborationMetricsRow?]) {
        let title = rows.compactMap({$0?.chartTitle}).first
        guard let _ = title else { return }
        verticalChartData = ChartStructure(title: title!, values: rows.compactMap({$0?.value}), legends: rows.compactMap({$0?.legend}))
    }
    
    private func fillTeamsByFunctionsLineChartData(for rows: [CollaborationMetricsRow?]) {
        let title = rows.compactMap({$0?.chartTitle}).first
        guard let _ = title else { return }
        let chartSubtitles = rows.compactMap({$0?.chartSubtitle}).removeDuplicates()
        var data = [[TeamsByFunctionsDataEntry]]()
        for chartSubtitle in chartSubtitles {
            let neededRow = rows.filter({$0?.chartSubtitle == chartSubtitle})
            data.append(neededRow.compactMap({TeamsByFunctionsDataEntry(refreshDate: $0?.legend, value: Int($0?.value ?? 0))}))
        }
        teamsByFunctionsLineChartData = [:]
        teamsByFunctionsLineChartData?[title!] = data
    }
    
    private func fillActiveUsersLineChartData(for rows: [CollaborationMetricsRow?]) {
        let title = rows.compactMap({$0?.chartTitle}).first
        guard let _ = title else { return }
        activeUsersLineChartData = ChartStructure(title: title!, values: rows.compactMap({$0?.value}), legends: rows.compactMap({$0?.legend}))
    }
    
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
    
    func formImageURL(from imagePath: String?) -> String {
        guard let imagePath = imagePath, !imagePath.isEmptyOrWhitespace() else { return "" }
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
    
    func formAnswerBody(from base64EncodedText: String?, isTipsAndTricks: Bool = false) -> NSMutableAttributedString? {
        guard let encodedText = base64EncodedText, let data = Data(base64Encoded: encodedText), let htmlBodyString = String(data: data, encoding: .utf8) else { return nil }
        
        var htmlAttrString = NSAttributedString(string: htmlBodyString)
        if htmlBodyString.isHtmlString, let attrString = htmlBodyString.htmlToAttributedString {
            htmlAttrString = attrString
        }
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
        guard isTipsAndTricks else { return res }
        res.enumerateAttributes(in: NSRange(location: 0, length: res.length), options: .longestEffectiveRangeNotRequired, using: { (attributes, range, _) in
            for attribute in attributes {
                if let fnt = attribute.value as? UIFont {
                    let font = fnt.withSize(16.0)
                    res.addAttribute(.font, value: font, range: range)
                }
            }
        })
        return res
    }
    
}

protocol AppSuiteIconDelegate: AnyObject {
    func appSuiteIconChanged(with data: Data?, status: LoadingStatus)
}
