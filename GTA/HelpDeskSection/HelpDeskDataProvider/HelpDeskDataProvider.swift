//
//  HelpDeskDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation
import UIKit

class HelpDeskDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    private var cacheManager: CacheManager = CacheManager()
    private var imageCacheManager: ImageCacheManager = ImageCacheManager()
    
    private(set) var quickHelpData = [QuickHelpRow]()
    private(set) var teamContactsData = [TeamContactsRow]()
    private(set) var myTickets: [GSDTickets]?// = [GSDMyTicketsRow]()
    private var refreshTimer: Timer?
    private var cachedReportData: Data?
    
    var quickHelpDataIsEmpty: Bool {
        return quickHelpData.isEmpty
    }
    
    var teamContactsDataIsEmpty: Bool {
        return teamContactsData.isEmpty
    }
    
    func getGSDStatus(completion: ((_ reportData: GSDStatus?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleGSDStatusSectionReport(reportData: data, isFromCache: true, errorCode: code, error: cachedError, completion: { (data, code, error, _) in
                if error == nil {
                    completion?(data, code, cachedError, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(nil, errorCode, ResponseError.serverError, false)
                    } else {
                        self?.handleGSDStatusSectionReport(reportData: reportResponse, isFromCache: false, errorCode: code, error: error, completion: completion)
                    }
                })
            })
        }
        
    }
        
    
    private func handleGSDStatusSectionReport(reportData: Data?, isFromCache: Bool, errorCode: Int, error: Error?, completion: ((_ reportData: GSDStatus?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = self.parseSectionReport(data: reportData)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdStatus.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if isFromCache {
                self.getCachedResponse(for: .getGSDStatus) {[weak self] (data, error) in
                    self?.processGSDStatus(data: data, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
                }
                return
            }
            self.apiManager.getGSDStatus(generationNumber: generationNumber!, completion: {[weak self] (data, errorCode, error) in
                let dataWithStatus = self?.addStatusRequest(to: data)
                self?.cacheData(dataWithStatus, path: .getGSDStatus)
                self?.processGSDStatus(data: dataWithStatus, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(nil, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, isFromCache)
                return
            }
            completion?(nil, 0, error, false)
        }
    }
    
    func getHelpDeskData(completion: ((_ reportData: HelpDeskResponse?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleHelpDeskSectionReport(data, code, cachedError, true, completion: { (cachedResponse, code, error, _) in
                if error == nil {
                    completion?(cachedResponse, code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(nil, errorCode, ResponseError.serverError, false)
                    } else {
                        self?.handleHelpDeskSectionReport(reportResponse, errorCode, error, false, completion: completion)
                    }
                })
            })
        }
    }
    
    private func handleHelpDeskSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool, completion: ((_ reportData: HelpDeskResponse?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = self.parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdProfile.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if isFromCache {
                self.getCachedResponse(for: .getHelpDeskData) {[weak self] (data, error) in
                    //if let _ = data {
                    self?.processHelpDeskData(data: data, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
                   // }
                }
                return
            }
            self.apiManager.getHelpDeskData(for: generationNumber!) {[weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getHelpDeskData)
                self?.processHelpDeskData(data: data, reportDataResponse: reportData, isFromCache, error: error, errorCode: errorCode, completion: completion)
            }
        } else {
            if error != nil || generationNumber == 0 {
                completion?(nil, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, isFromCache)
                return
            }
            let retError = ResponseError.serverError
            completion?(nil, 0, retError, isFromCache)
        }
    }
    
//    private func getSectionReport(completion: ((_ reportData: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
//        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
//            self?.cachedReportData = data
//            if let _ = data, cachedError == nil {
//                completion?(data, 200, cachedError, true)
//            }
//            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
//                self?.cacheData(reportResponse, path: .getSectionReport)
//                completion?(reportResponse, errorCode, error, false)
//            })
//        }
//    }
    
    func activateStatusRefresh(completion: @escaping ((_ isNeedToRefreshStatus: Bool) -> Void)) {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) {[weak self] (_) in
            self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                self?.cacheData(reportResponse, path: .getSectionReport)
                if let cahcedReport = self?.parseSectionReport(data: self?.cachedReportData), let serverReport = self?.parseSectionReport(data: reportResponse) {
                    completion(serverReport != cahcedReport)
                } else {
                    completion(true)
                }
            })
        }
    }
    
    func invalidateStatusRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func processHelpDeskData(data: Data?, reportDataResponse: ReportDataResponse?, _ isFromCache: Bool, error: Error?, errorCode: Int, completion: ((_ respone: HelpDeskResponse?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var helpDeskResponse: HelpDeskResponse?
        var retErr = error
        if let responseData = data {
            do {
                helpDeskResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        let indexes = getDataIndexes(columns: helpDeskResponse?.meta.widgetsDataSource?.params?.columns)
        helpDeskResponse?.indexes = indexes
        if let helpDeskResponse = helpDeskResponse {
            var missingHelpDeskFields = [String]()
            if (helpDeskResponse.serviceDeskPhoneNumber ?? "").isEmpty {
                missingHelpDeskFields.append("phoneNumber")
            }
            if (helpDeskResponse.serviceDeskEmail ?? "").isEmpty {
                missingHelpDeskFields.append("email")
            }
            if (helpDeskResponse.teamsChatLink ?? "").isEmpty {
                missingHelpDeskFields.append("teamsChat")
            }
            if !missingHelpDeskFields.isEmpty {
                retErr = ResponseError.missingFieldError(missingFields: missingHelpDeskFields)
            }
        }
        completion?(helpDeskResponse, errorCode, retErr, isFromCache)
    }
    
    private func processGSDStatus(data: Data?, reportDataResponse: ReportDataResponse?, _ isFromCache: Bool, error: Error?, errorCode: Int, completion: ((_ respone: GSDStatus?, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var statusResponse: GSDStatus?
        var retErr = error
        if let responseData = data {
            do {
                statusResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        if let requestDate = statusResponse?.data?.requestDate, isNeedToRemoveResponseForDate(requestDate) {
            cacheManager.removeCachedData(for: CacheManager.path.getGSDStatus.endpoint)
            completion?(nil, 0, ResponseError.noDataAvailable, isFromCache)
            return
        }
        let indexes = getDataIndexes(columns: statusResponse?.meta?.widgetsDataSource?.params?.columns)
        statusResponse?.indexes = indexes
        if (error != nil || statusResponse == nil) && isFromCache {
            retErr = ResponseError.noDataAvailable
        }
        completion?(statusResponse, errorCode, retErr, isFromCache)
    }
    
    private func addStatusRequest(to data: Data?) -> Data? {
        guard let _ = data, var stringData = String(data: data!, encoding: .utf8) else { return data }
        if let index = stringData.lastIndex(where: {$0 == "]"}) {
            let nextIndex = stringData.index(after: index)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = String.comapreDateFormat
            let dateString = dateFormatter.string(from: Date())
            stringData.insert(contentsOf: ", \"requestDate\" : \"\(dateString)\"", at: nextIndex)
            return stringData.data(using: .utf8)
        }
        return data
    }
    
    private func isNeedToRemoveResponseForDate(_ date: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String.comapreDateFormat
        guard var comparingDate = dateFormatter.date(from:date) else { return true }
        comparingDate.addTimeInterval(900)
        return Date() >= comparingDate
    }
    
    func formQuickHelpAnswerBody(from base64EncodedText: String?) -> NSMutableAttributedString? {
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
    
    /// Returns true if data was updated, otherwise false
    private func checkQuickHelpDataForUpdates(previousData: [QuickHelpRow]) -> Bool {
        guard previousData.count == quickHelpData.count else { return true }
        var dataWasUpdated = false
        for i in 0..<quickHelpData.count {
            if quickHelpData[i] != previousData[i] {
                dataWasUpdated = true
                break
            }
        }
        return dataWasUpdated
    }
    
    private func processQuickHelp(_ reportData: ReportDataResponse?, _ fromCache: Bool, _ quickHelpResponse: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        var quickHelpDataResponse: QuickHelpResponse?
        var retErr = error
        if let responseData = quickHelpResponse {
            do {
                quickHelpDataResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        let previousData = quickHelpData
        if let quickHelpResponse = quickHelpDataResponse {
            fillQuickHelpData(with: quickHelpResponse)
            if (quickHelpResponse.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        let dataWasChanged = checkQuickHelpDataForUpdates(previousData: previousData)
        completion?(dataWasChanged, errorCode, retErr, fromCache)
    }
    
    private func processQuickHelpSectionReport(_ reportResponse: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdQuickHelp.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdQuickHelp.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            getCachedResponse(for: .getQuickHelpData) {[weak self] (data, error) in
                if let _ = data {
                    self?.processQuickHelp(reportData, true, data, 200, error, completion)
                }
            }
            apiManager.getQuickHelp(generationNumber: generationNumber, completion: { [weak self] (quickHelpResponse, errorCode, error) in
                self?.cacheData(quickHelpResponse, path: .getQuickHelpData)
                self?.processQuickHelp(reportData, false, quickHelpResponse, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                self.quickHelpData = generationNumber == 0 ? [] : quickHelpData
                completion?(true, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            let retError = ResponseError.serverError
            completion?(true, 0, retError, fromCache)
        }
    }
    
    func getQuickHelpData(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ fromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            //if let _ = data {
            self?.processQuickHelpSectionReport(data, error == nil ? 200 : 0, error, true, { (dataWasChanged, code, error, _) in
                if error == nil {
                    completion?(dataWasChanged, code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    self?.processQuickHelpSectionReport(reportResponse, errorCode, error, false, completion)
                })
            })
        }
    }
    
    private func fillQuickHelpData(with quickHelpResponse: QuickHelpResponse) {
        let indexes = getDataIndexes(columns: quickHelpResponse.meta.widgetsDataSource?.params?.columns)
        var response: QuickHelpResponse = quickHelpResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        quickHelpData = response.data?.rows ?? []
    }
    
    private func processTeamContacts(_ reportData: ReportDataResponse?, _ teamContactsResponse: Data?, _ fromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        var teamContactsDataResponse: TeamContactsResponse?
        var retErr = error
        if let responseData = teamContactsResponse {
            do {
                teamContactsDataResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        var dataWasChanged: Bool = false
        if let teamContactsResponse = teamContactsDataResponse {
            dataWasChanged = fillTeamContactsData(with: teamContactsResponse)
            if (teamContactsResponse.data?.rows ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(dataWasChanged, errorCode, retErr, fromCache)
    }
    
    private func processTeamContactsSectionReport(_ reportResponse: Data?, _ fromCache: Bool, _ errorCode: Int, _ error: Error?, _ completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: reportResponse)
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdTeamContacts.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdTeamContacts.rawValue }?.generationNumber
        if let generationNumber = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getTeamContactsData) {[weak self] (data, error) in
                    self?.processTeamContacts(reportData, data, true, 200, error, completion)
                }
                return
            }
            apiManager.getTeamContacts(generationNumber: generationNumber, completion: { [weak self] (teamContactsResponse, errorCode, error) in
                self?.cacheData(teamContactsResponse, path: .getTeamContactsData)
                self?.processTeamContacts(reportData, teamContactsResponse, fromCache, errorCode, error, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                completion?(false, 0, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            let retError = ResponseError.serverError
            completion?(false, 0, retError, fromCache)
        }
    }
    
    func getTeamContactsData(completion: ((_ dataWasChanged: Bool, _ errorCode: Int, _ error: Error?, _ isFromCache: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, error) in
            self?.processTeamContactsSectionReport(data, true, error == nil ? 200 : 0, error, { (dataWasChanged, code, error, _) in
                if error == nil {
                    completion?(dataWasChanged, code, error, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    self?.processTeamContactsSectionReport(reportResponse, false, errorCode, error, completion)
                })
            })
        }
    }
    
    private func fillTeamContactsData(with teamContactsResponse: TeamContactsResponse) -> Bool {
        let indexes = getDataIndexes(columns: teamContactsResponse.meta.widgetsDataSource?.params?.columns)
        var response: TeamContactsResponse = teamContactsResponse
        if let rows = response.data?.rows {
            for (index, _) in rows.enumerated() {
                response.data?.rows?[index].indexes = indexes
            }
        }
        var isDataChanged: Bool = false
        if teamContactsData != response.data?.rows ?? [] {
            teamContactsData = response.data?.rows ?? []
            isDataChanged = true
        }
        teamContactsData.removeAll { $0.contactName == nil || ($0.contactName ?? "").isEmpty || $0.contactEmail == nil || ($0.contactEmail ?? "").isEmpty }
        return isDataChanged
    }
    
    // MARK: - My Tickets related methods
    
    /*
    func getMyTickets(completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleMyTicketsSectionReport(data, code, cachedError, true, { (code, error, _) in
                if error == nil {
                    completion?(code, cachedError, true)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.serverError, false)
                    } else {
                        self?.handleMyTicketsSectionReport(reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleMyTicketsSectionReport(_ report: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool,
                                            _ completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: report)
        let userEmail = KeychainManager.getUsername() ?? ""
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdTickets.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdTickets.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getGSDTickets(userEmail: userEmail)) {[weak self] (data, error) in
                    self?.processMyTickets(data, error == nil ? 200 : 0, error, true, completion)
                }
                return
            }
            apiManager.getGSDTickets(generationNumber: generationNumber!, userEmail: userEmail, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getGSDTickets(userEmail: userEmail))
                self?.processMyTickets(data, errorCode, error, false, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                myTickets = []
                completion?(errorCode, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(errorCode, ResponseError.commonError, fromCache)
        }
    }
 */
    func getMyTickets(completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        let userEmail = KeychainManager.getUsername() ?? ""
        getCachedResponse(for: .getGSDTickets(userEmail: userEmail)) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            if cachedError == nil {
                self?.processMyTickets(data, code, cachedError, completion)
                //completion?(code, cachedError, true)
            }
            self?.apiManager.getGSDTickets(completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getGSDTickets(userEmail: userEmail))
                self?.processMyTickets(data, errorCode, error, completion)
            })
        }
    }
    
    private func processMyTickets(_ response: Data?, _ errorCode: Int, _ error: Error?, _ completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        var ticketsResponse: GSDMyTickets?
        var retErr = error
        if let responseData = response {
            do {
                ticketsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        var dataWasChanged: Bool = false
        if let ticketsResponse = ticketsResponse {
            dataWasChanged = fillTicketsData(with: ticketsResponse)
            if (ticketsResponse.data?.isEmpty ?? true) {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(errorCode, retErr, dataWasChanged)
    }
    
    private func fillTicketsData(with ticketsResponse: GSDMyTickets) -> Bool {
        let response = ticketsResponse.data
        if let _ = response, (self.myTickets ?? []) != response! {
            self.myTickets = response!.compactMap({$0})
            return true
        }
        return false
    }
    
    // MARK: - Ticket comments related methods
    
    func getTicketComments(ticketNumber: String, completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        getCachedResponse(for: .getSectionReport) {[weak self] (data, cachedError) in
            let code = cachedError == nil ? 200 : 0
            self?.handleTicketCommentsSectionReport(ticketNumber: ticketNumber, data, code, cachedError, true, { (code, error, dataWasChanged) in
                if error == nil {
                    completion?(code, cachedError, dataWasChanged)
                }
                self?.apiManager.getSectionReport(completion: { [weak self] (reportResponse, errorCode, error) in
                    self?.cacheData(reportResponse, path: .getSectionReport)
                    if let _ = error {
                        completion?(errorCode, ResponseError.serverError, false)
                    } else {
                        self?.handleTicketCommentsSectionReport(ticketNumber: ticketNumber, reportResponse, errorCode, error, false, completion)
                    }
                })
            })
        }
    }
    
    private func handleTicketCommentsSectionReport(ticketNumber: String, _ report: Data?, _ errorCode: Int, _ error: Error?, _ fromCache: Bool,
                                            _ completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        let reportData = parseSectionReport(data: report)
        let userEmail = KeychainManager.getUsername() ?? ""
        let generationNumber = reportData?.data?.first { $0.id == APIManager.WidgetId.gsdTickets.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdComments.rawValue }?.generationNumber
        if let _ = generationNumber, generationNumber != 0 {
            if fromCache {
                getCachedResponse(for: .getGSDTicketComments(userEmail: userEmail, ticketNumber: ticketNumber)) {[weak self] (data, error) in
                    self?.processTicketComments(data, userEmail, error == nil ? 200 : 0, error, true, completion)
                }
                return
            }
            apiManager.getGSDTicketComments(generationNumber: generationNumber!, userEmail: userEmail, ticketNumber: ticketNumber, completion: { [weak self] (data, errorCode, error) in
                self?.cacheData(data, path: .getGSDTicketComments(userEmail: userEmail, ticketNumber: ticketNumber))
                self?.processTicketComments(data, userEmail, errorCode, error, false, completion)
            })
        } else {
            if error != nil || generationNumber == 0 {
                myTickets = []
                completion?(errorCode, error != nil ? ResponseError.commonError : ResponseError.noDataAvailable, fromCache)
                return
            }
            completion?(errorCode, ResponseError.commonError, fromCache)
        }
    }
    
    private func processTicketComments(_ response: Data?, _ userEmail: String, _ errorCode: Int, _ error: Error?, _ fromCache: Bool, _ completion: ((_ errorCode: Int, _ error: Error?, _ dataWasChanged: Bool) -> Void)? = nil) {
        var commentsResponse: GSDTicketCommentsResponse?
        var retErr = error
        if let responseData = response {
            do {
                commentsResponse = try DataParser.parse(data: responseData)
            } catch {
                retErr = ResponseError.parsingError
            }
        }
        var dataWasChanged: Bool = false
        let comments = commentsResponse?.data?.first?.value.first?.value?.data?.rows
        if let commentsResponse = commentsResponse {
            dataWasChanged = fillTicketComments(with: commentsResponse, userEmail: userEmail)
            if (comments ?? []).isEmpty {
                retErr = ResponseError.noDataAvailable
            }
        }
        completion?(errorCode, retErr, dataWasChanged)
    }
    
    private func fillTicketComments(with ticketComments: GSDTicketCommentsResponse, userEmail: String) -> Bool {
//        let indexes = getDataIndexes(columns: ticketComments.meta?.widgetsDataSource?.params?.columns)
//        var response = ticketComments.data?.first?.value.first?.value?.data?.rows
//        var ticketNumber = ""
//        if let rows = response {
//            for (index, _) in rows.enumerated() {
//                response?[index]?.indexes = indexes
//                let requestorEmail = response?[index]?.requestorEmail
//                //let decodedBody = formQuickHelpAnswerBody(from: response?[index]?.body)
//                response?[index]?.isSenderMe = userEmail == requestorEmail
//                //response?[index]?.decodedBody = decodedBody
//                ticketNumber = response?[index]?.ticketNumber ?? ""
//            }
//        }
//        let ticketIndex = self.myTickets?.firstIndex(where: {$0.ticketNumber == ticketNumber})
//        if let _ = response, self.myTickets?[ticketIndex ?? 0].comments != response! {
//            self.myTickets?[ticketIndex ?? 0].comments = response
//            return true
//        }
        return false
    }
    
    
    // MARK: - Other methods
    
    func formImageURL(from imagePath: String?) -> String? {
        guard let imagePath = imagePath, !imagePath.isEmpty else { return nil }
        guard !imagePath.contains("https://") else  { return imagePath }
        let imageURL = apiManager.baseUrl + "/" + imagePath.replacingOccurrences(of: "assets/", with: "assets/\(KeychainManager.getToken() ?? "")/")
        return imageURL
    }
    
    func getImageData(from url: URL, completion: @escaping ((_ imageData: Data?, _ error: Error?) -> Void)) {
        getCachedResponse(for: .getImageDataFor(detailsPath: url.absoluteString), completion: {[weak self] (cachedData, cachedError) in
            if cachedError == nil {
                completion(cachedData, nil)
            }
            self?.apiManager.loadImageData(from: url) { (data, response, error) in
                self?.cacheData(data, path: .getImageDataFor(detailsPath: url.absoluteString))
                DispatchQueue.main.async {
                    if cachedData == nil ? true : cachedData != data {
                        if cachedError == nil && error != nil { return }
                        completion(data, error)
                    }
                }
            }
        })
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
