//
//  UIExtension.swift
//  iptv
//
//  Created by Alexandr Kolganov on 02.11.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit


extension UIView {
    
    func addSubviewWithSomeSize(_ subView: UIView) {
        
        //set frame
        subView.frame = CGRect.init(origin: CGPoint(x:0, y:0), size: self.frame.size)
        
        //set constrains
        self.addSubview(subView)
        var viewBindingsDict = [String: AnyObject]()
        viewBindingsDict["subView"] = subView
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subView]|",
                                                                                 options: [], metrics: nil, views: viewBindingsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subView]|",                                                                                 options: [], metrics: nil, views: viewBindingsDict))
    }
    
    func findFirstInDeep(where predicate: (UIView) -> Bool) -> UIView? {
        for view in self.subviews {
            if predicate(view) {
                return view
            }
            else {
                let deepFind = view.findFirstInDeep(where: predicate)
                if deepFind != nil {
                    return deepFind
                }
            }
        }
        return nil
    }
}

extension UIViewController { //add/remove child  controller
    
    func containerAdd(childViewController:UIViewController, toView:UIView) {
        self.addChildViewController(childViewController)
        toView.addSubviewWithSomeSize(childViewController.view)
        childViewController.didMove(toParentViewController: self)
    }
    
    func containerRemove(childViewController:UIViewController) {
        self.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
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

    
    func simpleAlertChooser(title: String, message: String, buttonTitles: [String], completion: @escaping ((Int) -> Swift.Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for i in 0..<buttonTitles.count {
            let action = UIAlertAction(title: buttonTitles[i], style: .default, handler: { (_) in
                completion(i)
            })
            alertController.addAction(action)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }

}

