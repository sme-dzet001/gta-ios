//
//  ErrorHandler.swift
//  GTA
//
//  Created by Kostiantyn Dzetsiuk on 15.03.2021.
//

import Foundation

class ErrorHandler {
    
    static func getErrorMessage(for error: Error) -> String {
        let err = error as NSError
        switch err.code {
        case -1009:
            return "No network connection."
        default:
            return "Oops, something went wrong"
        }
    }
    
}
