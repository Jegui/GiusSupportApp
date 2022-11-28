//
//  HapticsService.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 20/10/2022.
//

import UIKit

final class HapticsService {
    static let shared = HapticsService()
    
    private init() {}
    
    func selectionVibrate() {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.prepare()
        selectionFeedbackGenerator.selectionChanged()
    }
    
    func vibrate(for type: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let notificationGenerator = UIImpactFeedbackGenerator(style: type)
        notificationGenerator.impactOccurred(intensity: intensity)
    }
}
