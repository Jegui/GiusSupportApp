//
//  GloveDetailViewModel.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 15/10/2022.
//

import Foundation

class GloveDetailViewModel: NSObject {
    var updateView: (()-> Void)?
    var distanceString: String = ""
    var accelerationString: String = ""
    
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
        distanceString = object.replacingOccurrences(of: ";", with: "\n")
        updateView?()
    }
}
