//
//  Preferences.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 19.05.2021.
//

import Foundation

class Preferences {
    
    static var officeId: Int?
    static var allowEmergencyOutageNotifications: Bool = true
    static var ticketsSortingType: SortType {
        get {
            let sortType = SortType(rawValue: UserDefaults.standard.string(forKey: Constants.sortingKey) ?? "")
            return sortType ?? .newToOld
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKeyPath: Constants.sortingKey)
        }
    }
    static var ticketsFilterType: FilterType {
        get {
            let filterType = FilterType(rawValue: UserDefaults.standard.string(forKey: Constants.filterKey) ?? "")
            return filterType ?? .all
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKeyPath: Constants.filterKey)
        }
    }
}
