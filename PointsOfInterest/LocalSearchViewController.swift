/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The primary view controller that displays search results.
*/

import UIKit
import CoreLocation
import CoreLocationUI
import MapKit

class LocalSearchViewController: BaseSearchViewController {
    
    private var places: [MKMapItem]? {
        didSet {
            if let places {
                let rows = places.map { Row(mapItem: $0) }
                updateCollectionViewSnapshot(rows)
            }
        }
    }
    
    private var suggestionController: SuggestionsViewController!
    private var searchController: UISearchController!
    
    private var locationObservation: NSKeyValueObservation?
    private var currentLocation: CLLocation? {
        didSet {
            guard let currentLocation else { return }
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(currentLocation) { (placemark, error) in
                guard error == nil else {
                    if let error = error as? NSError {
                        print("Reverse geocoding returned an error: \(error)")
                    }
                    return
                }
                
                // Refine the search results by providing location information.
                self.currentPlacemark = placemark?.first
                self.searchRegion = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 20_000, longitudinalMeters: 20_000)
                self.suggestionController.updatePlacemark(self.currentPlacemark, boundingRegion: self.searchRegion)
                
                // If there is no active search query, use a default query so the collection view isn't empty.
                if self.searchController.searchBar.text == "" {
                    self.search(for: NSLocalizedString("DEFAULT_SEARCH_QUERY", comment: "Default search query"))
                }
            }
        }
    }

    private var localSearch: MKLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            places = nil
            localSearch?.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        configureSearchController()
        
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
    
    private func configureSearchController() {
        suggestionController = SuggestionsViewController()
        searchController = UISearchController(searchResultsController: suggestionController)
        searchController.searchResultsUpdater = suggestionController
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = NSLocalizedString("SEARCH_BAR_PLACEHOLDER", comment: "Search bar placeholder text")
        
        // Place the search bar in the navigation bar.
        navigationItem.searchController = searchController
        
        // Keep the search bar visible at all times.
        navigationItem.hidesSearchBarWhenScrolling = false
        
        /*
         Search is presenting a view controller, and needs a controller in the presented view controller hierarchy
         to define the presentation context.
         */
        definesPresentationContext = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         guard let detailViewController = segue.destination as? LocationDetailsViewController else {
             return
         }
         
         if segue.identifier == LocationDetailsViewController.SegueID.showDetail.rawValue {
             // Get the single item.
             guard let selectedItemPath = collectionView.indexPathsForSelectedItems?.first,
                   let row = dataSource.itemIdentifier(for: selectedItemPath),
                   let mapItem = row.mapItem
                else { return }
             
             // Pass the selected map item and the bounding region to the location details view controller,
             // with the map centered on the placemark.
             var region = searchRegion
             region.center = mapItem.placemark.coordinate
             detailViewController.display(mapItem, in: region)
         }
     }
    
    /// - Parameter suggestedCompletion: A search completion that `MKLocalSearchCompleter` provides.
    ///     This view controller performs  a search with `MKLocalSearch.Request` using this suggested completion.
    private func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }
    
    /// - Parameter queryString: A search string from the text the user enters into `UISearchBar`.
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        // Only display results that are in travel-related categories.
        searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        // Confine the map search area to an area around the user's current location.
        searchRequest.region = searchRegion
        
        // Include only point-of-interest results. This excludes results based on address matches.
        searchRequest.resultTypes = .pointOfInterest
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [unowned self] (response, error) in
            guard error == nil else {
                self.displaySearchError(error)
                return
            }
            
            self.places = response?.mapItems
            
            // This view controller sets the map view's region in `prepareForSegue` based on the search response's bounding region.
            if let updatedRegion = response?.boundingRegion {
                self.searchRegion = updatedRegion
            }
        }
    }
    
    private func displaySearchError(_ error: Error?) {
        guard let error = error as NSError? else { return }
        
        let alertTitle = NSLocalizedString("SEARCH_RESULTS_ERROR_TITLE", comment: "Error alert title")
        let alertController = UIAlertController(title: alertTitle, message: error.description, preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: "OK alert button"), style: .default) { _ in
            // Add any additional button-handling code here.
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    override func configureResultCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: BaseSearchViewController.Row) {
        var content = UIListContentConfiguration.subtitleCell()

        if let mapItem = item.mapItem {
            content.text = mapItem.name
            content.secondaryText = mapItem.placemark.formattedAddress
            
            let symbolIcon = mapItem.pointOfInterestCategory?.symbolName ?? MKPointOfInterestCategory.defaultPointOfInterestSymbolName
            content.image = UIImage(systemName: symbolIcon)
        }

        cell.contentConfiguration = content
    }
}

// MARK: - UICollectionViewDelegate

extension LocalSearchViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView {
            performSegue(withIdentifier: LocationDetailsViewController.SegueID.showDetail.rawValue, sender: nil)
            
        } else if collectionView == suggestionController.collectionView,
           let row = suggestionController.dataSource.itemIdentifier(for: indexPath),
           let suggestion = row.searchCompletion {
            
            searchController.isActive = false
            searchController.searchBar.text = suggestion.title
            search(for: suggestion)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension LocalSearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        // This system calls this method when the user taps Search on the `UISearchBar` or on the keyboard.
        // Because the user didn't select a row with a suggested completion, run the search with the query text in
        // the search field.
        search(for: searchBar.text)
    }
}

extension LocalSearchViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        
        // Send the selection in the search controller back to this controller to dismiss the search controller.
        suggestionController.collectionView.delegate = self
    }
}
