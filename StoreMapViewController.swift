//
//  StoreMapViewController.swift
//  trendrise
//
//  Created by Analee Maharaj on 12/8/24.
//

import UIKit
import MapKit

class StoreMapViewController: UIViewController {

    
    
    @IBOutlet weak var mapView: MKMapView!
    // The item passed from RecommendationsViewController
    var selectedItem: String?
        
        // Define a more structured store representation
        struct StoreInfo {
            let name: String
            let coordinate: CLLocationCoordinate2D
            let itemsAvailable: [String]
        }
        
        // Comprehensive store database
        let storeDatabase: [StoreInfo] = [
            StoreInfo(
                name: "Nordstrom",
                coordinate: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
                itemsAvailable: ["Black Heels", "Gold Necklace", "Skinny Jeans", "Structured Tote"]
            ),
            StoreInfo(
                name: "Macy's",
                coordinate: CLLocationCoordinate2D(latitude: 30.2676, longitude: -97.7491),
                itemsAvailable: ["Pointed Flats", "Chic Scarf", "Jacket", "Ankle Strap Heels"]
            ),
            StoreInfo(
                name: "Target",
                coordinate: CLLocationCoordinate2D(latitude: 30.2711, longitude: -97.7505),
                itemsAvailable: ["Turtleneck", "Cardigan", "Basic Jeans", "Accessories"]
            ),
            StoreInfo(
                name: "Zara",
                coordinate: CLLocationCoordinate2D(latitude: 30.2652, longitude: -97.7395),
                itemsAvailable: ["Statement Earrings", "Faux Leather Jacket", "Dresses", "White Turtle Neck"]
            )
        ]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Filter and display relevant stores based on the selected item
            let relevantStores = storeDatabase.filter { store in
                guard let item = selectedItem else { return true }
                return store.itemsAvailable.contains { $0.lowercased() == item.lowercased() }
            }
            
            // If no specific stores found, use all stores
            let storesToDisplay = relevantStores.isEmpty ? storeDatabase : relevantStores
            
            // Add annotations for stores
            for store in storesToDisplay {
                let annotation = MKPointAnnotation()
                annotation.title = store.name
                annotation.subtitle = "Items: " + (selectedItem ?? "Various")
                annotation.coordinate = store.coordinate
                mapView.addAnnotation(annotation)
            }
            
            // Center the map
            if let centerStore = storesToDisplay.first {
                let region = MKCoordinateRegion(
                    center: centerStore.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                mapView.setRegion(region, animated: true)
            }
        }
    }
