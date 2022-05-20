/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A base view controller that provides the collection view infrastructure for all of the search view controllers.
*/

import Foundation
import MapKit
import UIKit

class BaseSearchViewController: UIViewController {
    enum Section {
        case main
    }
    
    struct Row: Hashable {
        var header: String?
        var searchCompletion: MKLocalSearchCompletion?
        var mapItem: MKMapItem?
        
        init(header: String) {
            self.header = header
        }
        
        init(searchCompletion: MKLocalSearchCompletion?) {
            self.searchCompletion = searchCompletion
        }
        
        init(mapItem: MKMapItem) {
            self.mapItem = mapItem
        }
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Row>! = nil
    var collectionView: UICollectionView!
    
    var searchRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    var currentPlacemark: CLPlacemark?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewHierarchy()
        configureDataSource()
    }
    
    private func configureViewHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .grouped)
            config.headerMode = .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }

    func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row>(handler: configureHeaderCell)
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row>(handler: configureResultCell)

        dataSource = UICollectionViewDiffableDataSource<Section, Row>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Row) -> UICollectionViewCell? in
            if indexPath.item == 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
    }
    
    func updateCollectionViewSnapshot(_ rows: [Row]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([Section.main])
        dataSource.apply(snapshot, animatingDifferences: false)
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Row>()

        var header = NSLocalizedString("SEARCH_RESULTS", comment: "Standard result text")
        if let city = currentPlacemark?.locality {
            let templateString = NSLocalizedString("SEARCH_RESULTS_LOCATION", comment: "Search result text with city")
            header = String(format: templateString, city)
        }
        let headerRow = Row(header: header)
        
        sectionSnapshot.append([headerRow])
        sectionSnapshot.append(rows)

        dataSource.apply(sectionSnapshot, to: Section.main, animatingDifferences: true)
    }
    
    func configureHeaderCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: Row) {
        var content = UIListContentConfiguration.groupedHeader()
        content.text = item.header
        cell.contentConfiguration = content
    }
    
    /// Override this method in a subclass to customize the cells.
    func configureResultCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: Row) {
        
    }
}
