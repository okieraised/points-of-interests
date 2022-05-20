/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that displays suggested search criteria.
*/

import UIKit
import MapKit

class SuggestionsViewController: BaseSearchViewController {
    
    private var searchCompleter: MKLocalSearchCompleter?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startProvidingCompletions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopProvidingCompletions()
    }
    
    private func startProvidingCompletions() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        searchCompleter?.region = searchRegion
        
        // Only include matches for travel-related points of interest, and exclude address-based results.
        searchCompleter?.resultTypes = .pointOfInterest
        searchCompleter?.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
    }
    
    private func stopProvidingCompletions() {
        searchCompleter = nil
    }
    
    func updatePlacemark(_ placemark: CLPlacemark?, boundingRegion: MKCoordinateRegion) {
        currentPlacemark = placemark
        searchCompleter?.region = searchRegion
    }

// MARK: Collection View Data Source

    /// - Tag: HighlightFragment
    override func configureResultCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: Row) {
        var content = UIListContentConfiguration.subtitleCell()

        if let suggestion = item.searchCompletion {
            // Each suggestion is an `MKLocalSearchCompletion` with a title, subtitle, and ranges that describe what part of the title
            // and subtitle match the current query string. Use the ranges to apply helpful highlighting of the text in
            // the completion suggestion that matches the current query fragment.
            content.attributedText = createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
            content.secondaryAttributedText = createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
        }

        cell.contentConfiguration = content
    }

    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")! ]
        let highlightedString = NSMutableAttributedString(string: text)

        // Each `NSValue` wraps an `NSRange` that functions as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }

        return highlightedString
    }
}

extension SuggestionsViewController: MKLocalSearchCompleterDelegate {

    /// - Tag: QueryResults
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // As the user types, new completion suggestions continuously return to this method.
        // Refresh the UI with the new results.
        let results = completer.results.map { result in
            return Row(searchCompletion: result)
        }
        updateCollectionViewSnapshot(results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle any errors that `MKLocalSearchCompleter` returns.
        if let error = error as NSError? {
            print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
        }
    }
}

extension SuggestionsViewController: UISearchResultsUpdating {

    /// - Tag: UpdateQuery
    func updateSearchResults(for searchController: UISearchController) {
        // Ask `MKLocalSearchCompleter` for new completion suggestions based on the change in the text that the user enters in `UISearchBar`.
        searchCompleter?.queryFragment = searchController.searchBar.text ?? ""
    }
}
