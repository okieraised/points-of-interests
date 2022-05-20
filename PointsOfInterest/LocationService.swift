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
    private var foregroundRestorationObserver: NSObjectProtocol?
    
    /// This property is  `@objc` so that the view controllers can observe when the user location changes through key-value observing.
    @objc dynamic var currentLocation: CLLocation?
    
    /// The view controller that presents any errors coming from location services.
    var errorPresentationTarget: UIViewController?
    
    override init() {
        super.init()
        locationManager.delegate = self
        
        let name = UIApplication.willEnterForegroundNotification
        foregroundRestorationObserver = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [unowned self] (_) in
            // Get a new location when returning from Settings to enable location services.
            self.requestLocation()
        }
    }

    func requestLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            displayLocationServicesDisabledAlert()
            return
        }
        
        let status = locationManager.authorizationStatus
        guard status != .denied else {
            displayLocationServicesDeniedAlert()
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    private func displayLocationServicesDisabledAlert() {
        let message = NSLocalizedString("LOCATION_SERVICES_DISABLED", comment: "Location services are disabled")
        let alertController = UIAlertController(title: NSLocalizedString("LOCATION_SERVICES_ALERT_TITLE", comment: "Location services alert title"),
                                                message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: "OK alert button"), style: .default) { _ in
            // Add any additional button-handling code here.
        }
        alertController.addAction(okAction)
        errorPresentationTarget?.present(alertController, animated: true, completion: nil)
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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle any errors that `CLLocationManager` returns.
    }
}

