# Interacting with nearby points of interest

Provide automatic search completions based on a user's partial search query, search the map for relevant locations nearby, and retrieve details for selected points of interest.

## Overview

The PointsOfInterest sample code project demonstrates how to programmatically search for map-based addresses and points of interest using a natural language string, and get more information for points of interest that the user selects on the map. The search results center around the user's current location.

## Request search completions
[`MKLocalSearchCompleter`][3] retrieves autocomplete suggestions for a partial search query within a map region. A user can type "cof," and a search completion suggests "coffee" as the query string. As the user types a query into a search bar, the sample app updates the [`queryFragment`][2] through the [`UISearchResultsUpdating`][4] protocol.

``` swift
func updateSearchResults(for searchController: UISearchController) {
    // Ask `MKLocalSearchCompleter` for new completion suggestions based on the change in the text that the user enters in `UISearchBar`.
    searchCompleter?.queryFragment = searchController.searchBar.text ?? ""
}
```
[View in Source](x-source-tag://UpdateQuery)

[2]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter/1452555-queryfragment
[3]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter
[4]:https://developer.apple.com/documentation/uikit/uisearchresultsupdating

## Receive completion results
Completion results represent fully formed query strings based on the query fragment the user types. The sample app uses completion results to populate UI elements, such as a table view, to quickly fill in a search query. The app receives the latest completion results as an array of [`MKLocalSearchCompletion`][5] objects by adopting the [`MKLocalSearchCompleterDelegate`][6] protocol.

``` swift
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
```
[View in Source](x-source-tag://QueryResults)

[5]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion
[6]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleterdelegate

## Highlight the relationship of a query fragment to the suggestion

Within the UI elements that represent each query result, the sample code uses the [`titleHighlightRanges`][7] and [`subtitleHighlightRanges`][8] on an `MKLocalSearchCompletion` to show how the query the user enters relates to the suggested result. For example, the following code applies a highlight with [`NSAttributedString`][9]:

``` swift
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
```
[View in Source](x-source-tag://HighlightFragment)

[7]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion/1451935-titlehighlightranges
[8]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion/1452489-subtitlehighlightranges
[9]:https://developer.apple.com/documentation/foundation/nsattributedstring

## Search for map items

An [`MKLocalSearch.Request`][10] takes either an [`MKLocalSearchCompletion`][5] or a natural language query string, and returns an array of [`MKMapItem`][11] objects. Each `MKMapItem` represents a geographic location, like a specific address, that matches the search query. The sample code asynchronously retrieves the array of `MKMapItem` objects by calling [`start(completionHandler:)`][12] on [`MKLocalSearch`][13].

``` swift
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
```
[View in Source](x-source-tag://SearchRequest)

[10]:https://developer.apple.com/documentation/mapkit/mklocalsearch/request
[11]:https://developer.apple.com/documentation/mapkit/mkmapitem
[12]:https://developer.apple.com/documentation/mapkit/mklocalsearch/1452652-start
[13]:https://developer.apple.com/documentation/mapkit/mklocalsearch


## Allow the user to select points of interest on the map
If a user is exploring the map, they can get information on a point of interest by tapping it. To enable these interactions, the sample code enables selectable map features as follows:

``` swift
mapView.selectableMapFeatures = [.pointsOfInterest]

// Filter out any points of interest that aren't related to travel.
let mapConfiguration = MKStandardMapConfiguration()
mapConfiguration.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)

mapView.preferredConfiguration = mapConfiguration
```
[View in Source](x-source-tag://SelectableFeature)

When the user taps a point of interest, the system calls [`mapView(_:, viewFor:)`][14] on the [`MKMapViewDelegate`][15] with an [`MKMapFeatureAnnotation`][16] that represents the tapped item. The annotation is customizable using the [`MKIconStyle`][17] property of `MKFeatureAnnotation`.

``` swift
if let tappedFeatureColor = annotation.iconStyle?.backgroundColor,
    let image = annotation.iconStyle?.image {
    
    markerAnnotationView.markerTintColor = tappedFeatureColor
    infoButton.tintColor = tappedFeatureColor
    
    let imageView = UIImageView(image: image.withTintColor(tappedFeatureColor, renderingMode: .alwaysOriginal))
    imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
    markerAnnotationView.leftCalloutAccessoryView = imageView
}
```
[View in Source](x-source-tag://IconStyle)

To get detailed information on the point of interest, like when searching for the destination with `MKLocalSearch`, the sample code turns the `MKFeatureAnnotation` into an `MKMapItem` by using [`MKMapItemRequest`][18].
``` swift
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
```
[View in Source](x-source-tag://MapItemRequest) 

[14]:https://developer.apple.com/documentation/mapkit/mkmapviewdelegate/1452045-mapview
[15]:https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
[16]:https://developer.apple.com/documentation/mapkit/mkmapfeatureannotation
[17]:https://developer.apple.com/documentation/mapkit/mkiconstyle
[18]:https://developer.apple.com/documentation/mapkit/mkmapitemrequest
