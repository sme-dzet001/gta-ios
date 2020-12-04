//
//  HelpDeskDataProvider.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 03.12.2020.
//

import Foundation

class HelpDeskDataProvider {
    
    private var apiManager: APIManager = APIManager(accessToken: KeychainManager.getToken())
    
    func getServiceDeskData(completion: ((_ reportData: HelpDeskResponse?, _ errorCode: Int, _ error: Error?) -> Void)? = nil) {
        apiManager.getSectionReport(sectionId: APIManager.SectionId.serviceDesk.rawValue) { [weak self] (reportResponse, errorCode, error) in
            let generationNumber = reportResponse?.data?.first { $0.id == APIManager.WidgetId.gsdProfile.rawValue }?.widgets?.first { $0.widgetId == APIManager.WidgetId.gsdProfile.rawValue }?.generationNumber
            if let _ = generationNumber {
                self?.apiManager.getServiceDeskData(for: generationNumber!, completion: completion)
            } else {
                completion?(nil, errorCode, error)
            }
        }
    }
    
}
