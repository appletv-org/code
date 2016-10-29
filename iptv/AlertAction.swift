//
//  AlertAction.swift
//  iptv
//
//  Created by Alexandr Kolganov on 22.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

extension UIViewController {

    func showAlertError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}
