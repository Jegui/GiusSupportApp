//
//  ViewController+Extension.swift
//  Basic Chat MVC
//
//  Created by Juan Emilio Eguizabal on 15/10/2022.
//

import UIKit


extension ViewController {
    ///A simple alert with no action.
    func presentAlert(title: String, description: String) {
        let alertVC = UIAlertController(title: title, message: description, preferredStyle: UIAlertController.Style.alert)

        let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        })

        alertVC.addAction(action)

        self.present(alertVC, animated: true, completion: nil)
    }
}
