/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A singleton object that handles requesting and updating the user location.
*/

import Foundation
import CoreLocation
import UIKit

class LocationService: NSObject {
    
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    /// This property is  `@objc` so that the view controllers can observe when the user location changes through key-value observing.
    @objc dynamic var currentLocation: CLLocation?
    
    /// The view controller that presents any errors coming from location services.
    weak var errorPresentationTarget: UIViewController?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    private func displayLocationServicesDeniedAlert() {
        let message = NSLocalizedString("LOCATION_SERVICES_DENIED", comment: "Location services are denied")
        let alertController = UIAlertController(title: NSLocalizedString("LOCATION_SERVICES_ALERT_TITLE", comment: "Location services alert title"),
                                                message: message,
                                                preferredStyle: .alert)
        let settingsButtonTitle = NSLocalizedString("BUTTON_SETTINGS", comment: "Settings alert button")
        let openSettingsAction = UIAlertAction(title: settingsButtonTitle, style: .default) { (_) in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                // Take the user to the Settings app to change permissions.
                UIApplication.shared.open(settingsURL, options: [:]) { _ in
                    // Add any additional code to run after this method completes here.
                }
            }
        }
        
        let cancelButtonTitle = NSLocalizedString("BUTTON_CANCEL", comment: "Location denied cancel button")
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            // Add any additional button-handling code here.
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(openSettingsAction)
        errorPresentationTarget?.present(alertController, animated: true, completion: nil)
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = locationManager.authorizationStatus
        if status == .denied {
            displayLocationServicesDeniedAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle any errors that `CLLocationManager` returns.
    }
}
