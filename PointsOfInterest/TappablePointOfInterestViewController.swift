/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to interact with the points of interest on the map.
*/

import Foundation
import UIKit
import MapKit

class TappablePointOfInterestViewController: UIViewController {
    
    private enum AnnotationReuseID: String {
        case featureAnnotation
    }
    
    @IBOutlet private weak var mapView: MKMapView!
    
    private var locationObservation: NSKeyValueObservation?
    private var currentLocation: CLLocation? {
        didSet {
            guard let currentLocation else { return }
            
            let mapRegion = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(mapRegion, animated: true)
        }
    }
    
    /// - Tag: SelectableFeature
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: AnnotationReuseID.featureAnnotation.rawValue)
        
        /*
         Limit the selection of features on the map to points of interest, such as hotels, parks, and restaurants.
         This disables the selection of territory labels, such as city and neighberhood labels, and physical features,
         such as mountain ranges.
         */
        mapView.selectableMapFeatures = [.pointsOfInterest]
        
        // Filter out any points of interest that aren't related to travel.
        let mapConfiguration = MKStandardMapConfiguration()
        mapConfiguration.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
        
        mapView.configuration = mapConfiguration
        
        // Set a default location.
        currentLocation = LocationService.shared.currentLocation
        
        // Modify the location as updates come in.
        locationObservation = LocationService.shared.observe(\.currentLocation, options: [.new]) { _, change in
            guard let value = change.newValue,
                  let location = value
                else { return }
            
            self.currentLocation = location
        }
    }
    
    /// - Tag: MapItemRequest
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let detailViewController = segue.destination as? LocationDetailsViewController else { return }
        
        if segue.identifier == LocationDetailsViewController.SegueID.showDetail.rawValue {
            guard let selectedAnnotation = mapView.selectedAnnotations.first,
                  let featureAnnotation = selectedAnnotation as? MKMapFeatureAnnotation
                else { return }
            
            /*
             An `MKMapFeatureAnnotation` only has limited information about the point of interest, such as the `title` and `coordinate`
             properties. To get additional information, use `MKMapItemRequest` to get an `MKMapItem`.
             */
            let request = MKMapItemRequest(mapFeatureAnnotation: featureAnnotation)
            request.getMapItem { mapItem, error in
                guard error == nil else {
                    self.displayError(error)
                    return
                }
                
                if let mapItem {
                    // Pass the selected map item and the bounding region to the location details view controller,
                    // with the map centered on the placemark.
                    var region = self.mapView.region
                    region.center = mapItem.placemark.coordinate
                    detailViewController.display(mapItem, in: region)
                }
            }
        }
    }
    
    /// - Tag: IconStyle
    private func setupPointOfInterestAnnotation(_ annotation: MKMapFeatureAnnotation) -> MKAnnotationView? {
        let markerAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: AnnotationReuseID.featureAnnotation.rawValue,
                                                                         for: annotation)
        if let markerAnnotationView = markerAnnotationView as? MKMarkerAnnotationView {
            
            markerAnnotationView.animatesWhenAdded = true
            
            /*
             Tapping a point of interest automatically selects the annotation. Selected annotations automatically
             show callouts when they're in an enabled state.
             */
            markerAnnotationView.canShowCallout = true
            
            /*
             When the user taps the detail disclosure button, use `mapView(_:annotationView:calloutAccessoryControlTapped:)`
             to determine which annotation they tapped.
             */
            let infoButton = UIButton(type: .detailDisclosure)
            markerAnnotationView.rightCalloutAccessoryView = infoButton
            
            /*
             A feature annotation has properties that describe the type of the annotation, such as a point of interest.
             A point of interest feature annotation also contains an icon style property, with icon and color information from
             the tapped icon. Use these properties to customize the annotation, such as by changing icon colors based on the tapped annotation,
             using the provided icon image, or picking an image based on the point-of-interest category.
             */
            if let tappedFeatureColor = annotation.iconStyle?.backgroundColor,
                let image = annotation.iconStyle?.image {
                
                markerAnnotationView.markerTintColor = tappedFeatureColor
                infoButton.tintColor = tappedFeatureColor
                
                let imageView = UIImageView(image: image.withTintColor(tappedFeatureColor, renderingMode: .alwaysOriginal))
                imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
                markerAnnotationView.leftCalloutAccessoryView = imageView
            }
        }
        
        return markerAnnotationView
    }
    
    private func displayError(_ error: Error?) {
        guard let error = error as NSError? else { return }
        
        let alertTitle = NSLocalizedString("SEARCH_RESULTS_ERROR_TITLE", comment: "Error alert title")
        let alertController = UIAlertController(title: alertTitle, message: error.description, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: "OK alert button"), style: .default) { _ in
            // Add any additional button-handling code here.
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension TappablePointOfInterestViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? MKMapFeatureAnnotation {
            // Provide a customized annotation view for a tapped point of interest.
            return setupPointOfInterestAnnotation(annotation)
        } else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let annotation = view.annotation, annotation.isKind(of: MKMapFeatureAnnotation.self) {
            performSegue(withIdentifier: LocationDetailsViewController.SegueID.showDetail.rawValue, sender: self)
        }
    }
}
