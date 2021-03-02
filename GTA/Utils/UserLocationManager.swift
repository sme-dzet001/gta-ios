//
//  UserLocationManager.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 31.12.2020.
//

import Foundation
import CoreLocation

protocol UserLocationManagerDelegate: class {
    func closestOfficeWasRetreived(officeCoord: (lat: Float, long: Float)?)
    func userDeniedToGetHisLocation()
    func locationManagerFailed(with error: Error)
}

class UserLocationManager: NSObject {
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    var officesCoordArray = [(lat: Float, long: Float)]()
    
    weak var userLocationManagerDelegate: UserLocationManagerDelegate?
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
    }
    
    /// - Returns: false - if user denied to get his location, otherwise returns true (user accepted to get his location, or his choice is not determined yet)
    func getCurrentUserLocation() -> Bool {
        locationManager.requestWhenInUseAuthorization()
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
            return true
        case .notDetermined:
            return true
        case .denied, .restricted:
            return false
        default:
            return true
        }
    }
    
    private func findClosestLocation() -> (lat: Float, long: Float)? {
        guard let userLocation = currentLocation else { return nil }
        let locationsArray = officesCoordArray.map { CLLocation(latitude: CLLocationDegrees($0.lat), longitude: CLLocationDegrees($0.long)) }
        guard let closestLoc = locationsArray.min(by: { $0.distance(from: userLocation) < $1.distance(from: userLocation) }) else { return nil }
        return (lat: Float(closestLoc.coordinate.latitude), long: Float(closestLoc.coordinate.longitude))
    }
}

extension UserLocationManager: CLLocationManagerDelegate {
    
    // trigers after user tap on 'Allow' or 'Disallow' on the dialog
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted {
            userLocationManagerDelegate?.userDeniedToGetHisLocation()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    // trigers after location was retreived
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            let closestOfficeCoord = findClosestLocation()
            userLocationManagerDelegate?.closestOfficeWasRetreived(officeCoord: closestOfficeCoord)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        userLocationManagerDelegate?.locationManagerFailed(with: error)
    }
}
