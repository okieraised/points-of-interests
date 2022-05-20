/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller showing details for a specific point-of-interest, including the address.
*/

import UIKit
import MapKit

class LocationDetailsViewController: UITableViewController {
    
    enum SegueID: String {
        /// This is the segue identifier that the storyboard uses to display this view controller from
        /// `LocalSearchViewController` and `TappablePointOfInterestViewController`.
        case showDetail
    }

    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var placePhoneLabel: UILabel!
    @IBOutlet weak var placeWebsiteLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    private var mapItem: MKMapItem?
    private var boundingRegion: MKCoordinateRegion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplayedData()
    }
    
    private func updateDisplayedData() {
        guard isViewLoaded, let mapItem = self.mapItem, let region = boundingRegion
            else { return }
        
        navigationItem.title = mapItem.name
        
        placeAddressLabel.text = mapItem.placemark.formattedAddress
        placePhoneLabel.text = mapItem.phoneNumber
        placeWebsiteLabel.text = mapItem.url?.absoluteString
        
        mapView.showAnnotations([mapItem.placemark], animated: false)
        mapView.region = region
    }
    
    @IBAction func openItemInMaps(_ sender: UIButton) {
        mapItem?.openInMaps(launchOptions: nil)
    }

    func display(_ mapItem: MKMapItem!, in region: MKCoordinateRegion) {
        self.mapItem = mapItem
        self.boundingRegion = region
        updateDisplayedData()
    }
}
