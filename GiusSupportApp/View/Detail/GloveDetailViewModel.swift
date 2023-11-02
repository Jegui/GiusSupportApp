//
//  GloveDetailViewModel.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 15/10/2022.
//

import Foundation
import UIKit
import AVFoundation
import CoreLocation

class GloveDetailViewModel: NSObject {
    
    let hapticsService = HapticsService.shared
    let synthesizer = AVSpeechSynthesizer()
    var locationManager = CLLocationManager()
    var updateView: (()-> Void)?
    var distanceString: String = ""
    var accelerationString: String = ""
    
    var locationString: String = ""
    
    private var distance: Int = 0 {
        didSet {
            var intensity: CGFloat = .zero
            switch distance {
            case 0...9:
                intensity = 1
            case 10...25:
                intensity = 0.8
            case  25...50:
                intensity = 0.3
            default:
                intensity = 0
            }
            if intensity > 0 {
                hapticsService.vibrate(for: .heavy, intensity: intensity)
            }
        }
    }
    
    init(updateView: (() -> Void)?) {
        super.init()
        self.updateView = updateView
        NotificationCenter.default.addObserver(self, selector: #selector(self.dataChanged(notification:)), name: NSNotification.Name(rawValue: "Notify"), object: nil)
        locationManager.delegate = self
           locationManager.desiredAccuracy = kCLLocationAccuracyBest
           locationManager.requestAlwaysAuthorization()
           if CLLocationManager.locationServicesEnabled(){
               locationManager.startUpdatingLocation()
           }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dataChanged(notification: Notification) {
        guard let object = notification.object as? String else {
            return
        }
        if object.contains("Accl") {
            accelerationString = object.replacingOccurrences(of: ";", with: "\n")
        } else if object.contains("Distance") {
            distanceString = object
            if let distanceString = object.split(separator: " ").last,
               let distance = Int(distanceString.replacingOccurrences(of: "}\n", with: "")){
                self.distance = distance
            }
        }
        if object.contains("HELP") {
            let mPhoneNumber = "+542915341997";
            let mMessage = "hello%20phone";
            if let url = URL(string: "sms://" + mPhoneNumber + "&body="+mMessage) {
                UIApplication.shared.open(url)
            }
        }
        if object.contains("GPS") {
            let utterance = AVSpeechUtterance(string: locationString)
            utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
            
            
            synthesizer.speak(utterance)
        }
        updateView?()
    }
}

extension GloveDetailViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation :CLLocation = locations[0] as CLLocation

        print("user latitude = \(userLocation.coordinate.latitude)")
        print("user longitude = \(userLocation.coordinate.longitude)")

      
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in
            if (error != nil){
                print("error in reverseGeocode")
            }
            let placemark = placemarks! as [CLPlacemark]
            if placemark.count>0{
                let placemark = placemarks![0]
                print(placemark.locality!)
                print(placemark.administrativeArea!)
                print(placemark.country!)

                self.locationString = "\(placemark.locality!), \(placemark.administrativeArea!), \(placemark.country!)"
            }
        }

    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }

}
