//
//  UIViewControllerExtension.swift
//  tvorg
//
//  Created by alex on 04.11.2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

extension UIViewController { //add/remove child  controller
    
    func containerAdd(childViewController:UIViewController, toView:UIView) {
        self.addChildViewController(childViewController)
        toView.addSubviewWithSomeSize(childViewController.view)
        childViewController.didMove(toParentViewController: self)
    }
    
    func containerRemove(childViewController:UIViewController) {
        childViewController.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
    }
    
    func containerReplace(fromController:UIViewController, toController:UIViewController, inView:UIView) {
        fromController.willMove(toParentViewController: nil)
        self.addChildViewController(toController)
        toController.view.frame = fromController.view.frame
        
        //transfer from top to bottom
        self.transition(from: fromController, to: toController, duration: 0.25, options: .transitionCrossDissolve, animations: {},
            completion:{ (finished) in
                fromController.removeFromParentViewController()
                toController.didMove(toParentViewController: self)
            }
        )
    }
    
    //if controller into navigation controller then title add to title of previous controller
    func addNavigationTitle(_ title:String) {
        guard let viewControllers = self.navigationController?.viewControllers,
            viewControllers.count >= 2,
            viewControllers[viewControllers.count - 2].title != nil
        
        else {
            self.title = title
            return
        }
        self.title = viewControllers[viewControllers.count - 2].title!  + "/" + title
    }
}

extension UIViewController { //simple alert actions

    func simpleAlert(title: String, message: String, buttonTitle: String, completion: (() -> Swift.Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: completion)
    }
    
    func simpleAlertOk(title: String, message: String, completion: (() -> Swift.Void)? = nil) {
        simpleAlert(title: title, message: message, buttonTitle: "Ok", completion: completion)
    }

    
    func simpleAlertChooser(title: String, message: String, buttonTitles: [String], prefferButton:Int = 0, completion: @escaping ((Int) -> Swift.Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for i in 0..<buttonTitles.count {
            
            let action = UIAlertAction(title: buttonTitles[i], style:  .default, handler: { (_) in
                    completion(i)
            })
            alertController.addAction(action)
            if i == prefferButton { //add hidden cancel action for exit by menu button
                alertController.preferredAction = action
                let cancelAction = UIAlertAction(title: nil, style:  .cancel, handler: { (_) in
                    completion(i)
                })
                alertController.addAction(cancelAction)
            }
        }
        
        //add alert cancel
        self.present(alertController, animated: true, completion: nil)
    }

}
