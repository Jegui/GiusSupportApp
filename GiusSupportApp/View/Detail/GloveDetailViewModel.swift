//
//  GloveDetailViewModel.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 15/10/2022.
//

import Foundation

class GloveDetailViewModel {
    var updateView: (()-> Void)?
    var distanceString: String = ""
    var accelerationString: String = ""
    
    init(updateView: (() -> Void)?) {
        self.updateView = updateView
        NotificationCenter.default.addObserver(self, selector: #selector(self.dataChanged(notification:)), name: NSNotification.Name(rawValue: "Notify"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func dataChanged(notification: Notification) {
        guard let object = notification.object else {
            return
        }
        distanceString = "\(object)"
        updateView?()
    }
}
