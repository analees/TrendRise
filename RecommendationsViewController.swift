//
//  RecommendationsViewController.swift
//  trendrise
//
//  Created by Analee Maharaj on 12/5/24.
//

import UIKit
import CoreML
import Vision
import MapKit

class RecommendationsViewController: UIViewController {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    @IBOutlet weak var recommendationimg1: UIImageView!
    
    @IBOutlet weak var recommendationimg2: UIImageView!
    
    @IBOutlet weak var recommendationimg3: UIImageView!
    
    @IBOutlet weak var newSuggestionsbtn: UIButton!
    
    @IBOutlet weak var recommendation1: UILabel!
    
    @IBOutlet weak var recommendation2: UILabel!
    
    @IBOutlet weak var recommendation3: UILabel!
    
    var selectedItemIdentifier: String?
        var confidenceLevel: Double?
        
        // Store Information Struct
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
                itemsAvailable: ["Statement Earrings", "Jacket", "Skinny Jeans","Turtleneck"]
            ),
            StoreInfo(
                name: "Macy's",
                coordinate: CLLocationCoordinate2D(latitude: 30.2676, longitude: -97.7491),
                itemsAvailable: ["Gold Necklace", "Pointed Flats",  "Ankle Strap Heels", "White Turtle Neck"]
            ),
            StoreInfo(
                name: "Target",
                coordinate: CLLocationCoordinate2D(latitude: 30.2711, longitude: -97.7505),
                itemsAvailable: ["Structured Tote", "Cardigan", "Basic Jeans", "Accessories"]
            ),
            StoreInfo(
                name: "Zara",
                coordinate: CLLocationCoordinate2D(latitude: 30.2652, longitude: -97.7395),
                itemsAvailable: ["Black Heels", "Faux Leather Jacket", "Dresses","Chic Scarf"]
            )
        ]
        
        let outfitRecommendations: [String: [[String]]] = [
            "blouse": [
                ["Black Heels", "Gold Necklace", "Skinny Jeans", "Structured Tote"],
                ["Pointed Flats", "Chic Scarf", "Structured Tote"]
            ],
            "boots": [
                ["Skinny Jeans", "White Turtle Neck", "Gold Hoops", "Brown Trenchcoat"],
                ["Floral Dress",  "Statement Earrings", "Faux Leather Jacket"]
            ],
            "dress": [
                ["Silver Heels", "Jacket", "Shoulder Bag", "Woven Clutch"],
                ["Ankle Strap Heels", "Wide Brim Hat", "Woven Clutch"]
            ],
            "turtleneck sweater": [
                ["Skirt", "Black Pants", "Black Boots", "Wool Hat"],
                ["Longline Cardigan", "Pearl Earrings", "Textured Boots"]
            ],
        ]
        
        private var currentIndex = 0
        
        override func viewDidLoad() {
            super.viewDidLoad()
            loadRecommendedImages()
            setupMapView()
            
            // Add tap gesture recognizers for each image
            recommendationimg1.isUserInteractionEnabled = true
            recommendationimg1.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:))))
            recommendationimg2.isUserInteractionEnabled = true
            recommendationimg2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:))))
            recommendationimg3.isUserInteractionEnabled = true
            recommendationimg3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:))))
        }
        
        // Setup initial map view
        private func setupMapView() {
            // Center the map
            let centerCoordinate = CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431)
            let region = MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            mapView.setRegion(region, animated: true)
        }
        
        // Load images for recommendations
        private func loadRecommendedImages() {
            guard let item = selectedItemIdentifier, let recommendations = outfitRecommendations[item] else {
                print("No recommendations found for the selected item.")
                return
            }
            
            let currentRecommendations = recommendations[currentIndex]
            recommendationimg1.image = UIImage(named: currentRecommendations[0])
            recommendationimg2.image = UIImage(named: currentRecommendations[2])
            recommendationimg3.image = UIImage(named: currentRecommendations[1])
            
            recommendation1.text = currentRecommendations[0]
            recommendation2.text = currentRecommendations[1]
            recommendation3.text = currentRecommendations[2]
            
            // Update map with stores for these items
            updateMapAnnotations(with: currentRecommendations)
        }
        
        // Update map annotations based on current recommendations
        private func updateMapAnnotations(with items: [String]) {
            // Clear existing annotations
            mapView.removeAnnotations(mapView.annotations)
            
            // Find stores with these items
            let relevantStores = storeDatabase.filter { store in
                return items.contains { item in
                    store.itemsAvailable.contains { $0.lowercased() == item.lowercased() }
                }
            }
            
            // Add annotations for relevant stores
            for store in relevantStores {
                let annotation = MKPointAnnotation()
                annotation.title = store.name
                annotation.subtitle = "Items: " + items.joined(separator: ", ")
                annotation.coordinate = store.coordinate
                mapView.addAnnotation(annotation)
            }
        }
        
        @IBAction func newsuggestions(_ sender: UIButton) {
            guard let item = selectedItemIdentifier, let recommendations = outfitRecommendations[item] else {
                print("No recommendations found for the selected item.")
                return
            }
            
            // Increment the index to move to the next set of recommendations
            currentIndex = (currentIndex + 1) % recommendations.count
            loadRecommendedImages()
        }
        
        @objc func imageTapped(_ sender: UITapGestureRecognizer) {
            guard let tappedImageView = sender.view as? UIImageView else { return }
            
            // Determine which image was tapped and its corresponding item
            var tappedItem: String?
            if tappedImageView == recommendationimg1 {
                tappedItem = recommendation1.text
            } else if tappedImageView == recommendationimg2 {
                tappedItem = recommendation2.text
            } else if tappedImageView == recommendationimg3 {
                tappedItem = recommendation3.text
            }
            
            // Find stores for this item
            let relevantStores = storeDatabase.filter { store in
                guard let item = tappedItem else { return false }
                return store.itemsAvailable.contains { $0.lowercased() == item.lowercased() }
            }
            
            // Zoom to the first relevant store
            if let firstStore = relevantStores.first {
                let region = MKCoordinateRegion(
                    center: firstStore.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                mapView.setRegion(region, animated: true)
            }
        }
    }
