//
//  GloveDetailViewModel.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 15/10/2022.
//

import Foundation

class GloveDetailViewModel: NSObject {
    
    let hapticsService = HapticsService.shared
    
    var updateView: (()-> Void)?
    var distanceString: String = ""
    var accelerationString: String = ""
    
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
        updateView?()
    }
}
