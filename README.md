# Searching for Nearby Points of Interest

Provide automatic search completions based on a user's partial search query, and search the map for relevant locations nearby.

## Overview

The MapSearch code sample demonstrates how to programmatically search for map-based addresses and points of interest using a natural language string. The places found are centered around the user's current location.

## Request Search Completions
[`MKLocalSearchCompleter`][3] retrieves auto-complete suggestions for a partial search query within a map region. A user can type "cof," and a search completion will suggest "coffee" as the query string. As the user types a query into a search bar, your app updates the [`queryFragment`][2] through the [`UISearchResultsUpdating`][4] protocol.

``` swift
func updateSearchResults(for searchController: UISearchController) {
    // Ask `MKLocalSearchCompleter` for new completion suggestions based on the change in the text entered in `UISearchBar`.
    searchCompleter?.queryFragment = searchController.searchBar.text ?? ""
}
```
[View in Source](x-source-tag://UpdateQuery)

[2]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter/1452555-queryfragment
[3]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter
[4]:https://developer.apple.com/documentation/uikit/uisearchresultsupdating

## Receive Completion Results
Completion results represent fully formed query strings based on the query fragment typed by the user. You can use completion results to populate UI elements like a table view, to quickly fill in a search query. You receive the latest completion results as an array of [`MKLocalSearchCompletion`][5] objects by adopting the [`MKLocalSearchCompleterDelegate`][6] protocol.

``` swift
func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    // As the user types, new completion suggestions are continuously returned to this method.
    // Overwrite the existing results, and then refresh the UI with the new results.
    completerResults = completer.results
    tableView.reloadData()
}

func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    // Handle any errors returned from MKLocalSearchCompleter.
    if let error = error as NSError? {
        print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
    }
}
```
[View in Source](x-source-tag://QueryResults)

[5]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion
[6]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleterdelegate

## Highlight the Relationship of a Query Fragment to the Suggestion

Within the UI elements representing each query result, you can use the [`titleHighlightRanges`][7] and [`subtitleHighlightRanges`][8] on a `MKLocalSearchCompletion` to show how the query entered by the user relates to the suggested result. For example, apply a highlight with [`NSAttributedString`][9].

``` swift
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)

    if let suggestion = completerResults?[indexPath.row] {
        // Each suggestion is a MKLocalSearchCompletion with a title, subtitle, and ranges describing what part of the title
        // and subtitle matched the current query string. The ranges can be used to apply helpful highlighting of the text in
        // the completion suggestion that matches the current query fragment.
        cell.textLabel?.attributedText = createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
        cell.detailTextLabel?.attributedText = createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
    }

    return cell
}

private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
    let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")! ]
    let highlightedString = NSMutableAttributedString(string: text)
    
    // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
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

## Search for Map Items

An [`MKLocalSearch.Request`][10] takes either an [`MKLocalSearchCompletion`][5] or a natural language query string, and returns an array of [`MKMapItem`][11] objects. Each `MKMapItem` represents a geographic location, like a specific address, matching the search query. You asynchronously retrieve the array of `MKMapItem` objects by calling [`start(completionHandler:)`][12] on [`MKLocalSearch`][13].

``` swift
private func search(using searchRequest: MKLocalSearch.Request) {
    // Confine the map search area to an area around the user's current location.
    searchRequest.region = boundingRegion
    
    // Include only point of interest results. This excludes results based on address matches.
    searchRequest.resultTypes = .pointOfInterest
    
    localSearch = MKLocalSearch(request: searchRequest)
    localSearch?.start { [unowned self] (response, error) in
        guard error == nil else {
            self.displaySearchError(error)
            return
        }
        
        self.places = response?.mapItems
        
        // Used when setting the map's region in `prepareForSegue`.
        if let updatedRegion = response?.boundingRegion {
            self.boundingRegion = updatedRegion
        }
    }
}
```
[View in Source](x-source-tag://SearchRequest)

[10]:https://developer.apple.com/documentation/mapkit/mklocalsearch/request
[11]:https://developer.apple.com/documentation/mapkit/mkmapitem
[12]:https://developer.apple.com/documentation/mapkit/mklocalsearch/1452652-start
[13]:https://developer.apple.com/documentation/mapkit/mklocalsearch
