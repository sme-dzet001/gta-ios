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
        case -1001:
            return "The request timed out."
        default:
            return "An unexpected error occurred. Please try logging in again."
        }
    }
    
}
