//
//  UserLocationManager.swift
//  GTA
//
//  Created by Ivan Shmyhovskyi on 31.12.2020.
//

import Foundation
import CoreLocation

class UserLocationManager {
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    private func getCurrentUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
            currentLocation = locationManager.location
        }
    }
    
    // TODO: Remove prints
    func findClosestLocation(from locCoordArr: [(lat: Float, long: Float)]) -> (lat: Float, long: Float)? {
        getCurrentUserLocation()
        guard let userLocation = currentLocation else { return nil }
        print(userLocation)
        let locationsArray = locCoordArr.map { CLLocation(latitude: CLLocationDegrees($0.lat), longitude: CLLocationDegrees($0.long)) }
        print(locationsArray)
        guard let closestLoc = locationsArray.min(by: { $0.distance(from: userLocation) < $1.distance(from: userLocation) }) else { return nil }
        print(closestLoc)
        return (lat: Float(closestLoc.coordinate.latitude), long: Float(closestLoc.coordinate.longitude))
    }
}
