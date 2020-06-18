//
//  ViewController.swift
//  IOSWeek12
//
//  Created by admin on 16/06/2020.
//  Copyright © 2020 Fred. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet weak var userMap: MKMapView!
    @IBOutlet weak var adresssLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    
    var previousLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // We ake the check as soon as the View Loads
        checkLocationServices()
        // We could do the map.delegate = self but we did it on the storyboard
    }
    // This returns the lat/long for the center of the current mapView/Usermap.
    func centerLocation(for userMap: MKMapView) -> CLLocation{
        
        let latitude = userMap.centerCoordinate.latitude
        let longtitude = userMap.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longtitude)
        
    }
        func setupLocationManager(){
            // We attach the delegate we have have made in the extension
            locationManager.delegate = self
            // We set the desired accuracy of the map to "Best"
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        // First we check if the overall device has LocationServices Enabled
        func checkLocationServices(){
            if CLLocationManager.locationServicesEnabled() {
                // If locationservice is Enabled, we start the LocationManager
                setupLocationManager()
                // We then check the App specific permissions
                checkLocationAuthorization()
            }else{
                // Should tell the user
                print("Location Services Not Enabled!")
            }
        }
        // Now we check what the App it self is allowed to do.
        func checkLocationAuthorization(){
            switch CLLocationManager.authorizationStatus() {
            // We are allowed to get the location when the App is in Use.
            // This is where we call all the functions. We should/Could put them all in 1 function that we call here instead, but ill leave it like this for now.
            case .authorizedWhenInUse:
            // You can also click a checkbox on the Mapview in the Storyboard.
                userMap.showsUserLocation = true
                centerViewOnUserLocation()
                // This starts the "didupdatelocations" in extensions
                locationManager.startUpdatingLocation()
                // We set previousLocation as present location
                previousLocation = centerLocation(for: userMap)
            // If user denies, you cant ask for permission again and user has to manually allow in settings
            case .denied:
                break
            // Here we will ask them for permission to use Location.
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            // Means that the permission cannot be changed, could be due to parental control.
            case .restricted:
                break
            // We are allowed to get the location, even when the App is in the background
            // Usually not used.
            case .authorizedAlways:
                break
            }
    }
    func centerViewOnUserLocation(){
        // Location is an optional, so we unwrap it with "if let" in an variable
        if let location = locationManager.location?.coordinate{
            // The Latitude, Longtitude is how much you want to Zoom in
            let region = MKCoordinateRegion.init(center: location,latitudinalMeters: regionInMeters,longitudinalMeters: regionInMeters)
            userMap.setRegion(region, animated: true)
        }
    }
    
}
extension ViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // If locations.last is = nil, nothing below this line will happen
        // Its like a smarter "If" or try/catch kinda thing
        guard let location = locations.last else{return}
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        userMap.setRegion(region, animated: true)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ userMap: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = centerLocation(for: userMap)
        let geocoder = CLGeocoder()
        // We need to make sure that previousLocation is not nil right away. 
        guard let previousLocation = self.previousLocation else{return}
        
        guard center.distance(from: previousLocation) > 50 else {return}
        
        self.previousLocation = center
        
        geocoder.reverseGeocodeLocation(center){ [weak self] (placemarks,error) in
            guard let self = self else {return}
            // This is just error handeling
            if let _ = error {
                print("GeoCoder ERROR!")
                return
            }
            guard let placemark = placemarks?.first else {
                print("PlaceMarks ERROR!")
                return
            }
            // We use ?? to create a Default value incase something is Nil
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            // We make it a async call.
            DispatchQueue.main.async {
                self.adresssLabel.text = "\(streetNumber) \(streetName)"
            }
            
        }
    }
}

