//
//  GloveDetailViewController.swift
//  GiusSupportApp
//
//  Created by Juan Emilio Eguizabal on 16/10/2022.
//

import UIKit

class GloveDetailViewController: UIViewController {
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var accelerationLabel: UILabel!
    
    var viewModel: GloveDetailViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = GloveDetailViewModel(updateView: nil)
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel?.updateView = {
            DispatchQueue.main.async { [weak self] in
                self?.distanceLabel.text = self?.viewModel?.distanceString
                self?.accelerationLabel.text = self?.viewModel?.accelerationString
            }
        }
    }
}
